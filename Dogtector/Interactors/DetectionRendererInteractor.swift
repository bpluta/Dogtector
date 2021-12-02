//
//  DetectionRendererInteractor.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import UIKit
import Combine

protocol DetectorRendererLogic {
    func render(observations: [Observation], over image: UIImage, canvasSize: CGSize, with previewSettings: DetectionPreviewSettings) -> AnyPublisher<UIImage,Never>
    func render(observations: [Observation], on detectionLayer: DetectionLayer, with previewSettings: DetectionPreviewSettings)
    func setupDetectionLayer() -> DetectionLayer
}

class DetectorRendererInteractor: DetectorRendererLogic {
    private let appState: Store<AppState>
    
    private var renderQueue = DispatchQueue(label: "com.detectorRendererInteractor.renderQueue", qos: .userInitiated)
    private var detectionData: [DetectionClassInfo]?
    
    private var cancelBag = CancelBag()
    
    init(appState: Store<AppState>) {
        self.appState = appState
        setupUpdatesForClassData()
    }
    
    // MARK: - Interface implementations
    func render(observations: [Observation], over image: UIImage, canvasSize: CGSize, with previewSettings: DetectionPreviewSettings) -> AnyPublisher<UIImage,Never> {
        Future<UIImage,Never> { [weak self] promise in
            self?.renderQueue.async {
                let imageSize = image.size
                guard let detectionLayer = self?.setupDetectionLayer() else {
                    return promise(.success(UIImage()))
                }
                
                detectionLayer.frame = CGRect(size: imageSize.normalize(by: canvasSize))
                self?.render(observations: observations, on: detectionLayer, with: previewSettings)
                
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
                
                let renderedImage = renderer.image { context in
                    UIGraphicsPushContext(context.cgContext)
                    image.draw(in: CGRect(size: imageSize))
                    UIGraphicsPopContext()
                    
                    let scale = imageSize.width / detectionLayer.frame.width
                    context.cgContext.scaleBy(x: scale, y: scale)
                    detectionLayer.render(in: context.cgContext)
                }
                return promise(.success(renderedImage))
            }
        }.eraseToAnyPublisher()
    }
    
    func render(observations: [Observation], on detectionLayer: DetectionLayer, with previewSettings: DetectionPreviewSettings) {
        detectionLayer.add(obervations: observations, with: previewSettings)
    }
    
    func setupDetectionLayer() -> DetectionLayer {
        let detectionLayer = DetectionLayer()
        detectionLayer.dataDelegate = self
        return detectionLayer
    }
}

// MARK: - Helpers
extension DetectorRendererInteractor {
    private func setupUpdatesForClassData() {
        detectionData = appState[\.detectorData.classInfo]
        appState.updates(for: \.detectorData.classInfo)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.detectionData = value
            }.store(in: cancelBag)
    }
}

// MARK: - DetectionLayerDataProvider
extension DetectorRendererInteractor: DetectionLayerDataProvider {
    func getDataForDetection(id: Int) -> DetectionClassInfo? {
        guard let detectionData = detectionData, id < detectionData.count else { return nil }
        return detectionData[id]
    }
}

// MARK: - Stub
class StubDetectorRendererInteractor: DetectorRendererLogic {
    func render(observations: [Observation], over image: UIImage, canvasSize: CGSize, with previewSettings: DetectionPreviewSettings) -> AnyPublisher<UIImage,Never> {
        Empty().eraseToAnyPublisher()
    }
    
    func render(observations: [Observation], on detectionLayer: DetectionLayer, with previewSettings: DetectionPreviewSettings) { }
    
    func setupDetectionLayer() -> DetectionLayer { .init() }
}
