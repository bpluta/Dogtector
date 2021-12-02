//
//  Strikethrough.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct Strikethrough: View {
    let lineWidth: CGFloat
    let scaleFactor: CGFloat
    
    init(lineWidth: CGFloat, scaleFactor: CGFloat = 1.0) {
        self.lineWidth = lineWidth
        self.scaleFactor = scaleFactor
    }
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let widthOffset = lineWidth / 2
                
                let initialStartX = widthOffset
                let initialStartY = widthOffset
                
                let initialEndX = width - widthOffset
                let initialEndY = height - widthOffset
                
                let fullLineLength = hypot(initialEndX - initialStartX, initialEndY - initialStartY)
                let lineLength = fullLineLength * scaleFactor
                
                let offsetFromCorner = (fullLineLength - lineLength) / 2
                
                let cos = (initialEndX - initialStartX) / fullLineLength
                let sin = (initialEndY - initialStartY) / fullLineLength
                
                let newStartX = initialStartX + offsetFromCorner * cos
                let newStartY = initialStartY + offsetFromCorner * sin
                
                let newEndX = initialEndX - offsetFromCorner * cos
                let newEndY = initialEndY - offsetFromCorner * sin
                    
                path.move(to: CGPoint(x: newStartX, y: newStartY))
                path.addLine(to: CGPoint(x: newEndX, y: newEndY))
            }
            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
    }
}

extension Image {
    func addStrikethrough(isStrikethroughDisplayed: Bool, strikethroughScale: CGFloat = 1.0) -> some View {
        GeometryReader { geometry in
            self
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1.0, contentMode: .fill)
                .overlay(ClippingStrikehtough(
                            canvasSize: geometry.size.width,
                            isStrikethroughDisplayed: isStrikethroughDisplayed,
                            strikethroughScale: strikethroughScale))
                .overlay(StrikethroughOverlay(
                            canvasSize: geometry.size.width,
                            isStrikethroughDisplayed: isStrikethroughDisplayed,
                            strikethroughScale: strikethroughScale))
                .compositingGroup()
        }
    }
    
    @ViewBuilder
    private func ClippingStrikehtough(canvasSize: CGFloat, isStrikethroughDisplayed: Bool, strikethroughScale: CGFloat = 1.0) -> some View {
        if isStrikethroughDisplayed {
            Strikethrough(
                lineWidth: canvasSize * 0.25,
                scaleFactor: strikethroughScale
            ).blendMode(.destinationOut)
        }
    }
    
    @ViewBuilder
    private func StrikethroughOverlay(canvasSize: CGFloat, isStrikethroughDisplayed: Bool, strikethroughScale: CGFloat = 1.0) -> some View {
        if isStrikethroughDisplayed {
            Strikethrough(
                lineWidth: canvasSize * 0.1,
                scaleFactor: strikethroughScale
            )
        }
    }
}

#if DEBUG
struct StrikethroughPreview: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 50) {
            Theme.Image.viewfinder.addStrikethrough(isStrikethroughDisplayed: true)
            Theme.Image.bolt.addStrikethrough(isStrikethroughDisplayed: true)
        }.frame(width: 50)
    }
}
#endif
