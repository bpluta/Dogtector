//
//  DetectionLayer.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

protocol DetectionLayerDataProvider: AnyObject {
    func getDataForDetection(id: Int) -> DetectionClassInfo?
}

class DetectionLayer: CALayer {
    weak var dataDelegate: DetectionLayerDataProvider?
    
    func clear() {
        CATransaction.begin()
        sublayers?.forEach { layer in
            layer.removeFromSuperlayer()
        }
        CATransaction.commit()
    }
    
    func add(obervations: [Observation], with settings: DetectionPreviewSettings) {
        sublayers?.forEach { layer in
            layer.removeFromSuperlayer()
        }
        obervations.forEach { observation in
            add(observation, with: settings)
        }
    }
    
    private func add(_ observation: Observation, with previewSettings: DetectionPreviewSettings) {
        guard
            let topObservation = observation.topObservation,
            let classData = dataDelegate?.getDataForDetection(id: topObservation.classIndex)
        else { return }
        
        if previewSettings.isDetectionFrameEnabled {
            let frameLayer = DetectionFrame(in: observation.rect.size, within: bounds.size, with: previewSettings)
            frameLayer.position = CGPoint(
                x: observation.rect.minX,
                y: observation.rect.minY
            )
            addSublayer(frameLayer)
        }
        
        if previewSettings.isAnnotationEnabled {
            let annotation = Annotation(
                observation: observation,
                text: classData.primaryName,
                image: classData.image ?? UIImage(),
                with: previewSettings
            )
            annotation.position = CGPoint(
                x: observation.rect.midX,
                y: observation.rect.midY + annotation.bounds.height / 2
            )
            addSublayer(annotation)
        }
    }
}
