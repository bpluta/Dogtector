//
//  CapturedImagePreview.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import Combine

struct ZoomableImagePreview: UIViewRepresentable {
    @Environment(\.injected) private var injected: DependencyContainer
    
    var previewSettings: DetectionPreviewSettings
    var size: CGSize
    let previewedImage: PreviewedImage?
    let onAnnotationTap: ((Observation) -> Void)
    
    func makeUIView(context: Context) -> ZoomableImagePreviewView {
        let view = ZoomableImagePreviewView(frame: .zero, detectionLayerProvider: context.coordinator, previewSettings: previewSettings)
        
        view.backgroundColor = Theme.Color.black
        view.onAnnotationTap = onAnnotationTap
        view.updateSize(with: previewedImage?.image?.size, on: size)
        view.load(image: previewedImage?.image)
        view.updateDetecions(with: previewedImage?.detections ?? [])
        
        return view
    }
    
    func updateUIView(_ uiView: ZoomableImagePreviewView, context: Context) {
        uiView.updateSettings(with: previewSettings)
        uiView.updateSize(with: previewedImage?.image?.size, on: size)
        uiView.load(image: previewedImage?.image)
        uiView.updateDetecions(with: previewedImage?.detections ?? [])
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// MARK: - Coordinator
extension ZoomableImagePreview {
    class Coordinator: NSObject, DetectionLayerProvider {
        let parent: ZoomableImagePreview

        init(_ parent: ZoomableImagePreview) {
            self.parent = parent
        }

        func setupDetectionLayer() -> DetectionLayer {
            parent.injected.interactors.detectorRendererInteractor.setupDetectionLayer()
        }

        func render(observations: [Observation], on detectionLayer: DetectionLayer, with previewSettings: DetectionPreviewSettings) {
            parent.injected.interactors.detectorRendererInteractor.render(observations: observations, on: detectionLayer, with: previewSettings)
        }
    }
}
