//
//  ObjectDecoder.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import Vision

protocol ObjectDecodable {
    var inputWidth: Int? { get set }
    var inputHeight: Int? { get set }
    
    func process(results: [Any], in bounds: CGRect, orientation: OutputOrientation) -> [Observation]
}

class ObjectDecoder: ObjectDecodable {
    var inputWidth: Int?
    var inputHeight: Int?
    
    let maxBoundingBoxes = 32
    
    let confidenceThreshold: Float = 0.05
    let iouThreshold: Float = 0.2
    
    var anchors: [[Float]] = [
        [10, 13,     16, 30,     33, 23],
        [30, 61,     62, 45,     59, 119],
        [116, 90,    156, 198,   373, 326]
    ]
    
    init() { }
    
    func getLayerSetup(from resultArray: MLMultiArray) -> Yolo5LayerSetup? {
        guard
            let inputHeight = inputHeight,
            let inputWidth = inputWidth,
            resultArray.shape.count == 5
        else { return nil }
        
        return Yolo5LayerSetup(
            class_amount: resultArray.shape[4].uint32Value - 5,
            confidence_threshold: confidenceThreshold,
            channel_stride: resultArray.strides[1].uint32Value,
            vertical_stride: resultArray.strides[2].uint32Value,
            horizontal_stride: resultArray.strides[3].uint32Value,
            boxes: resultArray.shape[1].uint32Value,
            rows: resultArray.shape[2].uint32Value,
            cols: resultArray.shape[3].uint32Value,
            vertical_block_size: Float(inputHeight) / resultArray.shape[2].floatValue,
            horizontal_block_size: Float(inputWidth) / resultArray.shape[3].floatValue
        )
    }
    
    func process(results: [Any], in bounds: CGRect, orientation: OutputOrientation) -> [Observation] {
        assertionFailure("Should be overriden in subclass")
        return []
    }
    
    static func recommendedDecoder(for device: MTLDevice?) -> ObjectDecoderType {
        guard let device = device else {
            return .cpu
        }
        if device.supportsFamily(.apple4) {
            return .metal
        } else {
            return .hybrid
        }
    }
    
    static func initializeDecoder(type: ObjectDecoderType, device: MTLDevice?) -> ObjectDecoder {
        guard let device = device else {
            return ObjectCPUDecoder()
        }
        switch type {
        case .metal:
            return ObjectMetalDecoder(device: device)
        case .hybrid:
            return ObjectHybridDecoder(device: device)
        case .cpu:
            return ObjectCPUDecoder()
        }
    }
    
    func enumerate(observations: [Observation]) -> [Observation] {
        observations.enumerated().map { (index, observation) in
            Observation(
                detectionIndex: index + 1,
                rect: observation.rect,
                score: observation.score,
                objects: observation.objects
            )
        }
    }
    
    static func getFrameDecoder(for orientation: OutputOrientation, bounds: CGRect) -> FrameDecoder {
        switch orientation {
        case .portarait:
            return PortraitFrameDecoder()
        case .landscapeLeft:
            return LandscapeLeftFrameDecoder(bounds: bounds)
        case .landscapeRight:
            return LandscapeRightFrameDecoder(bounds: bounds)
        case .upsideDown:
            return UpsideDownFrameDecoder(bounds: bounds)
        }
    }
}
