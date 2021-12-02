//
//  ObjectCPUDecoder.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Vision

class ObjectCPUDecoder: ObjectDecoder {
    override func process(results: [Any], in bounds: CGRect, orientation: OutputOrientation) -> [Observation] {
        guard
            let inputWidth = inputWidth,
            let inputHeight = inputHeight
        else { return [] }
        var predictionBoxes = [Observation]()
        let frameDecoder = Self.getFrameDecoder(for: orientation, bounds: bounds)
        for layer in results.indices {
            guard let results = results.compactMap({ $0 as? VNCoreMLFeatureValueObservation })[layer].featureValue.multiArrayValue else { continue }
            let layerPredictions = decodePredictions(
                from: results,
                frameDecoder: frameDecoder,
                anchors: anchors[layer],
                inputWidth: inputWidth,
                inputHeight: inputHeight,
                in: bounds
            )
            predictionBoxes.append(contentsOf: layerPredictions)
        }
        
        let filteredObservations = PredictionProcessor.nonMaxSuppression(boxes: predictionBoxes, limit: maxBoundingBoxes, threshold: iouThreshold)
        let indexedObservations = enumerate(observations: filteredObservations)
        return indexedObservations
    }
    
    private func decodePredictions(from results: MLMultiArray, frameDecoder: FrameDecoder, anchors: [Float], inputWidth: Int, inputHeight: Int, in bounds: CGRect) -> [Observation] {
        guard let layer = getLayerSetup(from: results) else { return [] }
        
        var predictionBoxes = [Observation]()
        
        let outputData = Array<Float>(UnsafeBufferPointer(start: results.dataPointer.assumingMemoryBound(to: Float.self), count: results.count))
        
        let horizontalScaleFactor = bounds.width / CGFloat(inputWidth)
        let verticalScaleFactor = bounds.height / CGFloat(inputHeight)
        
        let channelStride = Int(layer.channel_stride)
        let verticalStride = Int(layer.vertical_stride)
        let horizontalStride = Int(layer.horizontal_stride)
        
        let classAmount = Int(layer.class_amount)
        let confidenceThreshold = layer.confidence_threshold
        
        let boxes = Int(layer.boxes)
        let rows = Int(layer.rows)
        let cols = Int(layer.cols)
        
        for box in 0 ..< boxes {
            for row in 0 ..< rows {
                for col in 0 ..< cols {
                    let dataBaseIndex = box * channelStride + row * verticalStride + col * horizontalStride
                    let classPrecissionIndex = dataBaseIndex + 5
                    
                    let observationPrecission = sigmoid(outputData[dataBaseIndex + 4])
                    let observationX = (sigmoid(outputData[dataBaseIndex]) * 2.0 - 0.5 + Float(col)) * layer.horizontal_block_size
                    let observationY = (sigmoid(outputData[dataBaseIndex+1])) * 2.0 - 0.5 + Float(row) * layer.vertical_block_size
                    let observationWidth = pow(sigmoid(outputData[dataBaseIndex+2]) * 2.0, 2) * anchors[2 * box]
                    let observationHeight = pow(sigmoid(outputData[dataBaseIndex+3]) * 2.0, 2) * anchors[2 * box + 1]
                    
                    var observationItems = [Observation.Item]()
                    for objectClass in 0 ..< classAmount {
                        let classPrecission = sigmoid(outputData[classPrecissionIndex + objectClass])
                        let score = observationPrecission * classPrecission
                        guard score >= confidenceThreshold else { continue }
                         
                        let detectedObject = Observation.Item(classIndex: objectClass, score: score)
                        observationItems.append(detectedObject)
                    }
                    if observationItems.count > 0 {
                        let rawFrame = RawObservationFrame(
                            x: observationX,
                            y: observationY,
                            width: observationWidth,
                            height: observationHeight
                        )
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
        }
        return predictionBoxes
    }
    
    private func sigmoid(_ value: Float) -> Float {
        1.0 / (1.0 + exp(-value))
    }
}
