//
//  Annotation.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import UIKit

class Annotation: CALayer {
    let observation: Observation
    
    private let directionTriangleSize: CGFloat = 7
    private let fontSize: CGFloat = 16
    private let contentHeight: CGFloat = 45
    private let paddingOffset: CGFloat = 4
    private let maxWidth: CGFloat = 200
    
    init(observation: Observation, text: String, image: UIImage, with settings: DetectionPreviewSettings) {
        self.observation = observation
        super.init()
        
        let scalingFactor = settings.annotationSize
        
        let directionTriangleSize = directionTriangleSize * scalingFactor
        let contentHeight = contentHeight * scalingFactor
        let paddingOffset = paddingOffset * scalingFactor
        let maxWidth = maxWidth * scalingFactor
        let fontSize = fontSize * (0.5 * scalingFactor + 0.5)
        
        let imageSize = contentHeight - paddingOffset * 2
        let maxTextWidth = maxWidth - paddingOffset * 3 - imageSize
        
        // Text
        let textLayer = getTextLayer(text: text, fontSize: fontSize, maxWidth: maxTextWidth)
        let textX = 2 * paddingOffset + imageSize
        let textY = directionTriangleSize + (contentHeight - textLayer.frame.height) / 2
        textLayer.transform = CATransform3DMakeTranslation(textX, textY, 0)
        
        let contentWidth = textLayer.frame.width + paddingOffset * 4 + imageSize
        let contentSize = CGSize(width: contentWidth, height: contentHeight)
        
        // Image
        let imageLayer = getImageLayer(image: image, size: CGSize(width: imageSize, height: imageSize))
        let imageX = paddingOffset
        let imageY = paddingOffset + directionTriangleSize
        imageLayer.transform = CATransform3DMakeTranslation(imageX, imageY, 0)
        
        // Backround
        let backgroundLayer = getAnnotationBackground(
            directionTriangleSize: directionTriangleSize,
            size: contentSize
        )
        
        addSublayer(backgroundLayer)
        addSublayer(imageLayer)
        addSublayer(textLayer)
        let size = CGSize(width: contentSize.width, height: contentSize.height + directionTriangleSize)
        bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    }
    
    override init(layer: Any) {
        self.observation = Observation(detectionIndex: 0, rect: .init(), score: .init(), objects: .init())
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func getImageLayer(image: UIImage, size: CGSize) -> CALayer {
        let imageLayer = CALayer()
        let image = image.cgImage
        imageLayer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        imageLayer.contents = image
        imageLayer.contentsGravity = .resizeAspectFill
        
        let maskLayer = CAShapeLayer()
        let maskPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        maskLayer.path = maskPath.cgPath
        maskLayer.fillColor = Theme.Color.black.cgColor
        
        imageLayer.mask = maskLayer
        return imageLayer
    }
    
    private func getTextLayer(text: String, fontSize: CGFloat, maxWidth: CGFloat) -> CATextLayer {
        let textLayer = CATextLayer()
        
        textLayer.rasterizationScale = UIScreen.main.scale
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.alignmentMode = .center
        textLayer.foregroundColor = Theme.Color.black.cgColor
        textLayer.fontSize = fontSize
        textLayer.font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
        textLayer.isWrapped = false
        textLayer.truncationMode = .end
        textLayer.string = text
        
        let preferredSize = textLayer.preferredFrameSize()
        textLayer.frame = CGRect(x: 0, y: 0, width: min(maxWidth, preferredSize.width), height: preferredSize.height)
        
        return textLayer
    }
    
    private func getAnnotationBackground(directionTriangleSize: CGFloat, size: CGSize) -> CALayer {
        let layer = CAShapeLayer()
        let path = UIBezierPath()
        
        let fullFrameRect = CGRect(
            x: 0,
            y: 0,
            width: size.width,
            height: size.height + directionTriangleSize
        )
        let contentRect = CGRect(
            x: fullFrameRect.minX,
            y: fullFrameRect.minY + directionTriangleSize,
            width: fullFrameRect.width,
            height: fullFrameRect.height - directionTriangleSize
        )
        let radius = contentRect.height / 2
        
        path.move(to: CGPoint(x: contentRect.minX + radius, y: contentRect.minY))
        
        path.addLine(to: CGPoint(x: contentRect.maxX - contentRect.width / 2 + directionTriangleSize, y: contentRect.minY))
        path.addLine(to: CGPoint(x: contentRect.maxX - contentRect.width / 2, y: fullFrameRect.minY))
        path.addLine(to: CGPoint(x: contentRect.maxX - contentRect.width / 2 - directionTriangleSize, y: contentRect.minY))
        path.addArc(
            withCenter: CGPoint(x: contentRect.maxX - radius, y: contentRect.minY + radius),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: contentRect.maxX, y: contentRect.maxY - radius))
        path.addArc(
            withCenter: CGPoint(x: contentRect.maxX - radius, y: contentRect.maxY - radius),
            radius: radius,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: contentRect.minX + radius, y: contentRect.maxY))
        path.addArc(
            withCenter: CGPoint(x: contentRect.minX + radius, y: contentRect.maxY - radius),
            radius: radius,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: contentRect.minX, y: contentRect.minY + radius))
        path.addArc(
            withCenter: CGPoint(x: contentRect.minX + radius, y: contentRect.minY + radius),
            radius: radius,
            startAngle: .pi,
            endAngle: .pi * 3 / 2,
            clockwise: true
        )
        layer.path = path.cgPath
        layer.fillColor = Theme.Color.transparentWhite.cgColor
        
        return layer
    }
}
