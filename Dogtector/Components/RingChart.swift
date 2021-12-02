//
//  RingChart.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct RingChart<Content: View>: View {
    @State private var currentProgress: Float = 0
    @State private var isAnimationEnabled: Bool = false
    
    var progress: Float
    var thickness: CGFloat
    var backgroundColor: Color
    
    let content: Content
    
    init(progress: Float, thickness: CGFloat, backgroundColor: Color = Theme.Color.adaptiveLightGray.color, @ViewBuilder content: @escaping () -> Content) {
        self.progress = progress
        self.thickness = thickness
        self.content = content()
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            content
                .frame(
                    width: geometry.size.width - 2 * thickness,
                    height: geometry.size.height - 2 * thickness
                ).clipShape(Circle())
                .padding(.all, thickness)
                .overlay(
                    ProgressBackgroundCircle()
                        .frame(
                            width: geometry.size.width - thickness,
                            height: geometry.size.height - thickness
                        ).overlay(ProgressArc())
                )
        }.onAppear(perform: triggerProgressAnimation)
    }
    
    @ViewBuilder
    private func ProgressBackgroundCircle() -> some View {
        Circle()
            .stroke(backgroundColor, style: StrokeStyle(lineWidth: thickness, lineCap: .round, lineJoin: .round))
    }
    
    @ViewBuilder
    private func ProgressArc() -> some View {
        Circle()
            .trim(from: 0.0, to: CGFloat(currentProgress))
            .stroke(Theme.Color.primary.color, style: StrokeStyle(lineWidth: thickness, lineCap: .round, lineJoin: .round))
            .rotationEffect(.degrees(270))
            .animation(isAnimationEnabled ? .easeInOut(duration: Double(progress)) : nil)
    }
}

extension RingChart {
    private func triggerProgressAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isAnimationEnabled = true
            currentProgress = progress
        }
    }
}

#if DEBUG
struct RingChartPreview: PreviewProvider {
    private static let size: CGFloat = 100
    
    static var previews: some View {
        RingChart(progress: 0.5, thickness: 10) {
            Image("bordercollie_miniature")
                .resizable()
        }
        .frame(width: size, height: size)
        .previewLayout(.sizeThatFits)
    }
}
#endif
