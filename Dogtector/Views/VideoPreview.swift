//
//  VideoPreview.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import Combine

#if PREVIEW
struct VideoPreview: UIViewRepresentable {
    @Environment(\.injected) private var injected: DependencyContainer
    @Binding var shouldDisplayObservations: Bool
    
    var previewSettings: DetectionPreviewSettings
    var predictionsPublisher: ObservationPublisher
    var size: CGSize
    let onAnnotationTap: ((Observation) -> ())
    let onFrameBufferUpdate: (CVPixelBuffer) -> Void
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView(frame: .zero, detectionLayerProvider: context.coordinator, previewSettings: previewSettings)
        view.onBufferUpdateAction = onFrameBufferUpdate
        view.onAnnotationTap = onAnnotationTap
        
        context.coordinator.setupPredictionsPublisher(for: view)
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        if !shouldDisplayObservations {
            uiView.updateDetecions(with: [])
        }
        uiView.updateSettings(with: previewSettings)
        uiView.updateSize(with: size, on: size)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// MARK: - Coordinator
extension VideoPreview {
    class Coordinator: DetectionLayerProvider {
        let parent: VideoPreview
        
        var predictionsCancellable: AnyCancellable?
        
        init(_ parent: VideoPreview) {
            self.parent = parent
        }
        
        func setupPredictionsPublisher(for view: VideoPreviewView) {
            predictionsCancellable = parent.predictionsPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newObservations in
                    guard self?.parent.shouldDisplayObservations ?? false else { return }
                    view.updateDetecions(with: newObservations)
                }
        }
        
        func cancelPredictionPublisher() {
            predictionsCancellable?.cancel()
            predictionsCancellable = nil
        }
        
        func setupDetectionLayer() -> DetectionLayer {
            parent.injected.interactors.detectorRendererInteractor.setupDetectionLayer()
        }
        
        func render(observations: [Observation], on detectionLayer: DetectionLayer, with previewSettings: DetectionPreviewSettings) {
            parent.injected.interactors.detectorRendererInteractor.render(observations: observations, on: detectionLayer, with: previewSettings)
        }
    }
}
#endif
