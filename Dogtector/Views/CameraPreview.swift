//
//  NewObjectDetectionView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import AVFoundation
import Combine

struct CameraPreview: UIViewRepresentable {
    @Environment(\.injected) private var injected: DependencyContainer
    
    @Binding var shouldDisplayObservations: Bool
    
    var previewSettings: DetectionPreviewSettings
    var predictionsPublisher: ObservationPublisher
    var size: CGSize
    
    let session: AVCaptureSession
    let onAnnotationTap: ((Observation) -> ())
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView(frame: .zero, detectionLayerProvider: context.coordinator, previewSettings: previewSettings)
        
        view.backgroundColor = Theme.Color.black
        view.videoPreviewLayer?.cornerRadius = 0
        view.videoPreviewLayer?.connection?.videoOrientation = .portrait
        view.videoPreviewLayer?.session = session
        view.onAnnotationTap = onAnnotationTap
        view.updateSize(with: size, on: size)

        context.coordinator.setupPredictionsPublisher(for: view)
        
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        if !shouldDisplayObservations {
            uiView.updateDetecions(with: [])
        }
        uiView.updateSettings(with: previewSettings)
        uiView.updateSize(with: size, on: size)
    }
    
    static func dismantleUIView(_ uiView: CameraPreviewView, coordinator: Coordinator) {
        coordinator.cancelPredictionPublisher()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// MARK: - Coordinator
extension CameraPreview {
    class Coordinator: DetectionLayerProvider {
        let parent: CameraPreview
        
        var predictionsCancellable: AnyCancellable?
        
        init(_ parent: CameraPreview) {
            self.parent = parent
        }
        
        func setupPredictionsPublisher(for view: CameraPreviewView) {
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
