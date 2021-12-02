//
//  ObjectDecoderModels.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import CoreML

enum ObjectDecoderType: String {
    case metal
    case hybrid
    case cpu
}

struct ModelOutputLayer {
    let boxes: Int
    let rows: Int
    let cols: Int
    
    let channelStride: Int
    let verticalStride: Int
    let horizontalStride: Int
    
    let verticalBlockSize: Float
    let horizontalBlockSize: Float
    
    let classAmount: Int
    
    init(from layer: MLMultiArray, inputWidth: Int, inputHeight: Int) {
        boxes = layer.shape[1].intValue
        rows = layer.shape[2].intValue
        cols = layer.shape[3].intValue
        channelStride = layer.strides[1].intValue
        verticalStride = layer.strides[2].intValue
        horizontalStride = layer.strides[3].intValue
        verticalBlockSize = Float(inputHeight) / Float(rows)
        horizontalBlockSize = Float(inputWidth) / Float(cols)
        classAmount = layer.shape[4].intValue - 5
    }
}

struct Observation: Identifiable {
    let detectionIndex: Int
    let rect: CGRect
    let score: Float
    let objects: [Item]
    
    let id = UUID()
    
    var topObservation: Item? {
        objects.sorted(by: { $0.score > $1.score }).first
    }
    
    struct Item: Identifiable {
        let id = UUID()
        let classIndex: Int
        let score: Float
    }
}

extension Observation: Hashable {
    static func == (lhs: Observation, rhs: Observation) -> Bool {
        lhs.rect == rhs.rect && lhs.score == rhs.score
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(score)
        hasher.combine(rect.origin.x)
        hasher.combine(rect.origin.y)
        hasher.combine(rect.size.width)
        hasher.combine(rect.size.height)
    }
}
