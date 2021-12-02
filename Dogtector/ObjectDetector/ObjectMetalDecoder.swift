//
//  ObjectMetalDecoder.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Vision

class ObjectMetalDecoder: ObjectDecoder {
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
        guard let function = gpuFunctionLibary?.makeFunction(name: "decode_yolo5") else { return }
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
            var layerSetup = getLayerSetup(from: results)
            
            let totalCount = results.strides[0].intValue
            let boxes = results.shape[1].intValue
            let rows = results.shape[2].intValue
            let cols = results.shape[3].intValue
            
            var returnedBufferCount: Int32 = 0
            
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
            let outputBuffer = device?.makeBuffer(
                length: MemoryLayout<Yolo5ObjectObservation>.size * totalCount,
                options: .storageModeShared
            )
            let returnedCountBuffer = device?.makeBuffer(
                bytes: &returnedBufferCount,
                length: MemoryLayout<Int32>.size,
                options: .storageModeShared
            )
            
            guard let commandBuffer = commandQueue?.makeCommandBuffer(),
                  let commandEncoder = commandBuffer.makeComputeCommandEncoder()
            else { continue }
            
            commandEncoder.setComputePipelineState(pipeline)
            
            commandEncoder.setBuffer(dataBuffer, offset: 0, index: 0)
            commandEncoder.setBuffer(layerSetupBuffer, offset: 0, index: 1)
            commandEncoder.setBuffer(anchorsBuffer, offset: 0, index: 2)
            commandEncoder.setBuffer(outputBuffer, offset: 0, index: 3)
            commandEncoder.setBuffer(returnedCountBuffer, offset: 0, index: 4)
            
            let threadsPerGrid = MTLSize(width: cols, height: rows, depth: boxes)
            let maxThreadsPerThreadGroup = pipeline.maxTotalThreadsPerThreadgroup
            
            let widthThreadsPerGroup = min(Int(cols), maxThreadsPerThreadGroup)
            let heightThreadsPerGroup = max(1, min(Int(rows), maxThreadsPerThreadGroup / widthThreadsPerGroup))
            let depthThreadsPerGroup = max(1, min(Int(rows), maxThreadsPerThreadGroup / (heightThreadsPerGroup * widthThreadsPerGroup)))
            
            let threadsPerThreadgroup = MTLSize(
                width: widthThreadsPerGroup,
                height: heightThreadsPerGroup,
                depth: depthThreadsPerGroup
            )
            dispatchGroup.enter()
            commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            commandEncoder.endEncoding()
            commandBuffer.addCompletedHandler { buffer in
                defer { dispatchGroup.leave() }
                guard
                    let resultCountPointer = returnedCountBuffer?.contents().bindMemory(to: Int32.self, capacity: MemoryLayout<Int32>.size),
                    let resultBufferPointer = outputBuffer?.contents().bindMemory(to: Yolo5ObjectObservation.self, capacity: MemoryLayout<Yolo5ObjectObservation>.size * Int(resultCountPointer.pointee))
                else { return }

                let count = resultCountPointer.pointee
                guard count > 0 else { return }

                let observations = Array(UnsafeBufferPointer(start: resultBufferPointer, count: Int(count)))

                let horizontalScaleFactor = bounds.width / CGFloat(inputWidth)
                let verticalScaleFactor = bounds.height / CGFloat(inputHeight)

                var observationDict: [Observation: [Observation.Item]] = [:]
                for observation in observations {
                    let rawFrame = RawObservationFrame(
                        x: observation.x,
                        y: observation.y,
                        width: observation.width,
                        height: observation.height
                    )

                    let width = frameDecoder.computeWidth(for: rawFrame, scaleFactor: horizontalScaleFactor)
                    let height = frameDecoder.computeHeight(for: rawFrame, scaleFactor: verticalScaleFactor)

                    let x = frameDecoder.computeX(for: rawFrame, width: width, scaleFactor: horizontalScaleFactor)
                    let y = frameDecoder.computeY(for: rawFrame, height: height, scaleFactor: verticalScaleFactor)

                    let rect = CGRect(x: x, y: y, width: width, height: height)
                    let observationPrecission = observation.observationPrecission

                    let rootItem = Observation(detectionIndex: 0, rect: rect, score: observationPrecission, objects: [])
                    let item = Observation.Item(classIndex: Int(observation.classId), score: observation.precission)

                    if observationDict[rootItem] != nil {
                        observationDict[rootItem]?.append(item)
                    } else {
                        observationDict[rootItem] = [item]
                    }
                }

                for observation in observationDict.keys {
                    guard let objects = observationDict[observation] else { continue }
                    let prediction = Observation(
                        detectionIndex: observation.detectionIndex,
                        rect: observation.rect,
                        score: observation.score,
                        objects: objects
                    )
                    predictionBoxes.append(prediction)
                }
            }
            commandBuffer.commit()
        }
        dispatchGroup.wait()
        let filteredObservations = PredictionProcessor.nonMaxSuppression(boxes: predictionBoxes, limit: maxBoundingBoxes, threshold: iouThreshold)
        let indexedObservations = enumerate(observations: filteredObservations)
        
        return indexedObservations
    }
}
