//
//  DetectionFrame.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import UIKit

class DetectionFrame: CAShapeLayer {
    init(in size: CGSize, within canvasSize: CGSize, with settings: DetectionPreviewSettings) {
        super.init()
        let framePath = getFramePath(in: size, within: canvasSize, with: settings)
        path = framePath.cgPath
        fillColor = UIColor.clear.cgColor
        strokeColor = UIColor(settings.detectionFrameColor).cgColor
        opacity = 0.7
        lineWidth = 3
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func getFramePath(in size: CGSize, within canvasSize: CGSize, with settings: DetectionPreviewSettings) -> UIBezierPath {
        let path = UIBezierPath()
        
        let horizontalSpace = size.width / 4
        let verticalSpace = size.height / 4
        let baseLength = min((size.width - horizontalSpace) / 2, (size.height - verticalSpace) / 2)
        let multiplier = min(max(size.width, size.height) / min(size.width, size.height), 1.5)
        
        let maxHorizontalLength = canvasSize.width / 4
        let maxVerticalLength = canvasSize.height / 4
        
        let horizontalLength = min(size.width > size.height ? baseLength * multiplier : baseLength, maxHorizontalLength)
        let verticalLength = min(size.height > size.width ? baseLength * multiplier : baseLength, maxVerticalLength)
        
        let maxRadius = min(canvasSize.width, canvasSize.height) / 12
        
        let radius = min(min(size.width, size.height) / 6, maxRadius)
        
        path.move(to: CGPoint(x: size.width - horizontalLength, y: 0))
        path.addLine(to: CGPoint(x: size.width - radius, y: 0))
        path.addArc(
            withCenter: CGPoint(x: size.width - radius, y: radius),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: size.width, y: verticalLength))
        
        path.move(to: CGPoint(x: size.width, y: size.height - verticalLength))
        path.addLine(to: CGPoint(x: size.width, y: size.height - radius))
        path.addArc(
            withCenter: CGPoint(x: size.width - radius, y: size.height - radius),
            radius: radius,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: size.width - horizontalLength, y: size.height))
        
        path.move(to: CGPoint(x: horizontalLength, y: size.height))
        path.addLine(to: CGPoint(x: radius, y: size.height))
        path.addArc(
            withCenter: CGPoint(x: radius, y: size.height - radius),
            radius: radius,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: 0, y: size.height - verticalLength))
        
        path.move(to: CGPoint(x: 0, y: verticalLength))
        path.addLine(to: CGPoint(x: 0, y: radius))
        path.addArc(
            withCenter: CGPoint(x: radius, y: radius),
            radius: radius,
            startAngle: .pi,
            endAngle: .pi * 3 / 2,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: horizontalLength, y: 0))
        
        return path
    }
}
