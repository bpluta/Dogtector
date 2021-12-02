//
//  PreviewView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import UIKit
import Combine

protocol DetectionLayerProvider: AnyObject {
    func setupDetectionLayer() -> DetectionLayer
    func render(observations: [Observation], on detectionLayer: DetectionLayer, with previewSettings: DetectionPreviewSettings)
}

class PreviewView: UIView {
    private var detections: [Observation] = []
    private var previewSettings: DetectionPreviewSettings
    
    var detectionLayer: DetectionLayer
    var onAnnotationTap: ((Observation) -> Void)?
    
    weak var detectionLayerProvider: DetectionLayerProvider?
    
    private var detectionLayerUpdateSubject = PassthroughSubject<Void,Never>()
    private var awaitingTapCancellable: AnyCancellable?
    
    init(frame: CGRect, detectionLayerProvider: DetectionLayerProvider, previewSettings: DetectionPreviewSettings) {
        self.previewSettings = previewSettings
        self.detectionLayerProvider = detectionLayerProvider
        self.detectionLayer = detectionLayerProvider.setupDetectionLayer()
        
        super.init(frame: frame)
        setupView()
    }
    
    func setupView() {
        layer.addSublayer(detectionLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let detectionLayerProvider = detectionLayerProvider else { return }
        detectionLayerProvider.render(observations: detections, on: detectionLayer, with: previewSettings)
        detectionLayerUpdateSubject.send(())
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard
            touches.count == 1,
            let point = touches.first?.location(in: self)
        else { return }
        guard let annotationLayer = testPointForAnnotation(point) else {
            setupAwaitingTapGesture(for: point)
            return
        }
        onAnnotationTap?(annotationLayer.observation)
    }
    
    func testPointForAnnotation(_ point: CGPoint) -> Annotation? {
        var annotation: Annotation?
        if let annotationLayer = layer.hitTest(point) as? Annotation {
            annotation = annotationLayer
        } else if let textLayer = layer.hitTest(point) as? CATextLayer,
                  let parentLayer = textLayer.superlayer as? Annotation {
            annotation = parentLayer
        }
        return annotation
    }
    
    private func setupAwaitingTapGesture(for point: CGPoint) {
        awaitingTapCancellable = detectionLayerUpdateSubject
            .sink { [weak self] in
                if let annotation = self?.testPointForAnnotation(point) {
                    self?.awaitingTapCancellable = nil
                    self?.onAnnotationTap?(annotation.observation)
                }
            }
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + .milliseconds(300)) {
            self.awaitingTapCancellable?.cancel()
            self.awaitingTapCancellable = nil
        }
    }
    
    func updateSize(with imageSize: CGSize?, on canvasSize: CGSize) {
        guard let imageSize = imageSize else { return }
        let normalizedSize = imageSize.normalize(by: canvasSize)

        guard detectionLayer.frame.size != normalizedSize else { return }

        let xOffset = (canvasSize.width - normalizedSize.width) / 2
        let yOffset = (canvasSize.height - normalizedSize.height) / 2

        detectionLayer.frame = CGRect(x: xOffset, y: yOffset, width: normalizedSize.width, height: normalizedSize.height)
    }
}

extension PreviewView {
    func updateSettings(with previewSettings: DetectionPreviewSettings) {
        self.previewSettings = previewSettings
        setNeedsDisplay()
    }
    
    func updateDetecions(with detections: [Observation]) {
        self.detections = detections
        setNeedsDisplay()
    }
}
