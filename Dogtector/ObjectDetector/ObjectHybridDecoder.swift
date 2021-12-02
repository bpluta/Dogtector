//
//  ObjectHybridDecoder.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Vision

class ObjectHybridDecoder: ObjectDecoder {
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue?
    var pipeline: MTLComputePipelineState?
    var commandBuffer: MTLCommandBuffer?
    
    init(device: MTLDevice) {
        super.init()
        setupMetal(for: device)
    }
    
    func setupMetal(for device: MTLDevice) {
        self.device = device
        commandQueue = device.makeCommandQueue()
        let gpuFunctionLibary = device.makeDefaultLibrary()
        guard let function = gpuFunctionLibary?.makeFunction(name: "decode_yolo5_hybrid") else { return }
        pipeline = try? device.makeComputePipelineState(function: function)
    }
    
    override func process(results: [Any], in bounds: CGRect, orientation: OutputOrientation) -> [Observation] {
        guard
            let inputWidth = inputWidth,
            let inputHeight = inputHeight,
            let pipeline = pipeline
        else { return [] }
        
        var predictionBoxes = [Observation]()
        let dispatchGroup = DispatchGroup()
        
        let frameDecoder = Self.getFrameDecoder(for: orientation, bounds: bounds)
        
        for layer in results.indices {
            guard let results = results.compactMap({ $0 as? VNCoreMLFeatureValueObservation })[layer].featureValue.multiArrayValue else { continue }
            let boxes = results.shape[1].intValue
            let rows = results.shape[2].intValue
            let cols = results.shape[3].intValue
            
            let channelStride = results.strides[1].intValue
            let verticalStride = results.strides[2].intValue
            let horizontalStride = results.strides[3].intValue
            
            let classAmount = results.shape[4].intValue - 5
            
            var layerSetup = getLayerSetup(from: results)
            
            let totalCount = results.strides[0].intValue
            
            let dataBuffer = device?.makeBuffer(
                bytes: results.dataPointer,
                length: MemoryLayout<Float>.size * totalCount,
                options: .storageModeShared
            )
            let layerSetupBuffer = device?.makeBuffer(
                bytes: &layerSetup,
                length: MemoryLayout<Yolo5LayerSetup>.size,
                options: .storageModeShared
            )
            let anchorsBuffer = device?.makeBuffer(
                bytes: anchors[layer].withUnsafeBytes({ $0.baseAddress! }),
                length: MemoryLayout<Float>.size * anchors[layer].count,
                options: .storageModeShared
            )
            
            // Command encoding
            guard let commandBuffer = commandQueue?.makeCommandBuffer(),
                  let commandEncoder = commandBuffer.makeComputeCommandEncoder()
            else { continue }
            
            commandEncoder.setComputePipelineState(pipeline)
            
            commandEncoder.setBuffer(dataBuffer, offset: 0, index: 0)
            commandEncoder.setBuffer(layerSetupBuffer, offset: 0, index: 1)
            commandEncoder.setBuffer(anchorsBuffer, offset: 0, index: 2)
            
            let gridWidth = pipeline.threadExecutionWidth
            let gridHeight = pipeline.maxTotalThreadsPerThreadgroup / gridWidth
            let gridDepth = max(1, pipeline.maxTotalThreadsPerThreadgroup / (gridWidth * gridHeight))
            let threadsPerThreadgroup = MTLSizeMake(gridWidth, gridHeight, gridDepth)
            
            let threadgroupsPerGrid = MTLSize(
                width: (Int(rows) + gridWidth - 1) / gridWidth,
                height: (Int(cols) + gridHeight - 1) / gridHeight,
                depth: (Int(boxes) + gridDepth - 1) / gridDepth
            )
            commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            commandEncoder.endEncoding()
            
            dispatchGroup.enter()
            
            let horizontalScaleFactor = bounds.width / CGFloat(inputWidth)
            let verticalScaleFactor = bounds.height / CGFloat(inputHeight)
            
            commandBuffer.addCompletedHandler { [weak self] buffer in
                let processedDataBuffer = dataBuffer?.contents().bindMemory(to: Float.self, capacity: MemoryLayout<Float>.size * totalCount)
                let processedData = Array(UnsafeBufferPointer(start: processedDataBuffer, count: Int(totalCount)))
                let confidenceThreshold = self?.confidenceThreshold ?? 0
                
                for box in 0..<boxes {
                    for row in 0..<rows {
                        for col in 0..<cols {
                            let dataBaseIndex = box * channelStride + row * verticalStride + col * horizontalStride
                            let observationPrecission = processedData[dataBaseIndex + 4]
                            guard observationPrecission > confidenceThreshold else { continue }
                            
                            let classPrecissionIndex = dataBaseIndex + 5
                            
                            let rawFrame = RawObservationFrame(
                                x: processedData[dataBaseIndex],
                                y: processedData[dataBaseIndex + 1],
                                width: processedData[dataBaseIndex + 2],
                                height: processedData[dataBaseIndex + 3]
                            )
                            var observationItems = [Observation.Item]()
                            for objectClass in 0..<classAmount {
                                let classPrecission = processedData[classPrecissionIndex + objectClass]
                                let score = observationPrecission * classPrecission
                                guard score >= confidenceThreshold else { continue }
                                let observationItem = Observation.Item(classIndex: objectClass, score: score)
                                observationItems.append(observationItem)
                            }
                            
                            guard !observationItems.isEmpty else { continue }
                            let width = frameDecoder.computeWidth(for: rawFrame, scaleFactor: horizontalScaleFactor)
                            let height = frameDecoder.computeHeight(for: rawFrame, scaleFactor: verticalScaleFactor)
                            let x = frameDecoder.computeX(for: rawFrame, width: width, scaleFactor: horizontalScaleFactor)
                            let y = frameDecoder.computeY(for: rawFrame, height: height, scaleFactor: verticalScaleFactor)
                            
                            let observation = Observation(
                                detectionIndex: 0,
                                rect: CGRect(x: x, y: y, width: width, height: height),
                                score: observationPrecission,
                                objects: observationItems
                            )
                            predictionBoxes.append(observation)
                        }
                    }
                }
                dispatchGroup.leave()
            }
            commandBuffer.commit()
        }
        dispatchGroup.wait()
        
        let filteredObservations = PredictionProcessor.nonMaxSuppression(boxes: predictionBoxes, limit: maxBoundingBoxes, threshold: iouThreshold)
        let indexedObservations = enumerate(observations: filteredObservations)
        return indexedObservations
    }
}
