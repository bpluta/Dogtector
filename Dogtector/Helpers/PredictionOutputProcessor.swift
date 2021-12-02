//
//  PredictionOutputProcessor.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import UIKit

enum PredictionProcessor {
    static func nonMaxSuppression(boxes: [Observation], limit: Int, threshold: Float) -> [Observation] {
        let sortedIndices = boxes.indices.sorted { boxes[$0].score > boxes[$1].score }
        
        var selected: [Observation] = []
        var active = [Bool](repeating: true, count: boxes.count)
        var activeLeft = active.count
        
        outer: for i in 0..<boxes.count {
            if active[i] {
                let boxA = boxes[sortedIndices[i]]
                selected.append(boxA)
                if selected.count >= limit { break }
                
                for j in i+1 ..< boxes.count {
                    if active[j] {
                        let boxB = boxes[sortedIndices[j]]
                        if intersectionOverUnion(a: boxA.rect, b: boxB.rect) > threshold {
                            active[j] = false
                            activeLeft -= 1
                            if activeLeft <= 0 { break outer }
                        }
                    }
                }
            }
        }
        return selected
    }

    private static func intersectionOverUnion(a: CGRect, b: CGRect) -> Float {
        let areaA = a.width * a.height
        if areaA <= 0 { return 0 }
        
        let areaB = b.width * b.height
        if areaB <= 0 { return 0 }
        
        let intersectionMinX = max(a.minX, b.minX)
        let intersectionMinY = max(a.minY, b.minY)
        let intersectionMaxX = min(a.maxX, b.maxX)
        let intersectionMaxY = min(a.maxY, b.maxY)
        let intersectionArea = max(intersectionMaxY - intersectionMinY, 0) * max(intersectionMaxX - intersectionMinX, 0)
        return Float(intersectionArea / (areaA + areaB - intersectionArea))
    }
}

