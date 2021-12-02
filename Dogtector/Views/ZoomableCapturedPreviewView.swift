//
//  ZoomableImagePreviewView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import UIKit

class ZoomableImagePreviewView: UIView {
    private let previewView: CapturedImagePreviewView
    private let scrollablePreviewContainer = UIView()
    
    var onAnnotationTap: ((Observation) -> Void)? {
        didSet { previewView.onAnnotationTap = onAnnotationTap }
    }
    
    init(frame: CGRect, detectionLayerProvider: DetectionLayerProvider, previewSettings: DetectionPreviewSettings) {
        previewView = CapturedImagePreviewView(frame: frame, detectionLayerProvider: detectionLayerProvider, previewSettings: previewSettings)
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.maximumZoomScale = AppDefaults.maximumImageZoomScale
        scrollView.minimumZoomScale = AppDefaults.minimumImageZoomScale
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        
        let scrollableContainer = setupScrollablePreviewContainer()
        scrollableContainer.contentMode = .scaleAspectFit
        scrollableContainer.translatesAutoresizingMaskIntoConstraints = true
        scrollableContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollableContainer.frame = scrollView.bounds
        
        scrollView.addSubview(scrollableContainer)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    private func setupScrollablePreviewContainer() -> UIView {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollablePreviewContainer.addSubview(previewView)
        previewView.topAnchor.constraint(equalTo: scrollablePreviewContainer.topAnchor).isActive = true
        previewView.bottomAnchor.constraint(equalTo: scrollablePreviewContainer.bottomAnchor).isActive = true
        previewView.leadingAnchor.constraint(equalTo: scrollablePreviewContainer.leadingAnchor).isActive = true
        previewView.trailingAnchor.constraint(equalTo: scrollablePreviewContainer.trailingAnchor).isActive = true
        previewView.layer.addSublayer(previewView.detectionLayer)
        
        return scrollablePreviewContainer
    }
}

// MARK: - UIScrollViewDelegate
extension ZoomableImagePreviewView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        scrollablePreviewContainer
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}

// MARK: - Preview View adapter
extension ZoomableImagePreviewView {
    func load(image: UIImage?) {
        previewView.load(image: image)
    }
    
    func updateSettings(with previewSettings: DetectionPreviewSettings) {
        previewView.updateSettings(with: previewSettings)
    }
    func updateSize(with imageSize: CGSize?, on canvasSize: CGSize) {
        previewView.updateSize(with: imageSize, on: canvasSize)
    }
    
    func updateDetecions(with detections: [Observation]) {
        previewView.updateDetecions(with: detections)
    }
}
