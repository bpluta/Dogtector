//
//  LoadingShimmer.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct LoadingShimmer: View {
    @State var startPoint: UnitPoint
    @State var endPoint: UnitPoint
    
    private let appearance: Appearance
    
    private let trimmingValue: CGFloat
    private let expandBeyondFrame: Bool
    
    private let defaultStep: CGFloat = 0.1
    private let stepValue: CGFloat
    
    init(appearance: Appearance = .regular, trimmingValue: CGFloat = 1.0, expandBeyondFrame: Bool = true) {
        self.appearance = appearance
        self.trimmingValue = trimmingValue
        self.stepValue = defaultStep / trimmingValue
        self.expandBeyondFrame = expandBeyondFrame
        self.startPoint = UnitPoint(x: -2 * stepValue, y: 0)
        self.endPoint = UnitPoint(x: 1 - 2 * stepValue, y: 0)
    }
    
    var body: some View {
        LinearGradient(stops: gradientStops, startPoint: startPoint, endPoint: endPoint)
            .onAppear {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                        startPoint = UnitPoint(x: 1.0 / (expandBeyondFrame ? trimmingValue : 1.0), y: 0)
                        endPoint = UnitPoint(x: 2.0 / (expandBeyondFrame ? trimmingValue : 1.0), y: 0)
                    }
                }
            }
    }
    
    private var gradientStops: [Gradient.Stop] {[
        Gradient.Stop(
            color: appearance.primaryColor,
            location: 0
        ),
        Gradient.Stop(
            color: appearance.secondaryColor,
            location: stepValue
        ),
        Gradient.Stop(
            color: appearance.primaryColor,
            location: stepValue * 2
        )
    ]}
}

extension LoadingShimmer {
    enum Appearance {
        case light
        case regular
        case dark
        
        var primaryColor: Color {
            switch self {
            case .light:
                return Theme.Color.listCell.color
            case .regular:
                return Theme.Color.listCellInverted.color
            case .dark:
                return Theme.Color.adaptiveGray.color
            }
        }
        
        var secondaryColor: Color {
            switch self {
            case .light:
                return Theme.Color.listBackground.color
            case .regular:
                return Theme.Color.listBackgroundInverted.color
            case .dark:
                return Theme.Color.lightestAdaptiveGray.color
            }
        }
    }
}

#if DEBUG
struct LoadingLinePreview: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 10) {
            LoadingShimmer()
                .frame(width: 150, height: 20)
            LoadingShimmer()
                .frame(width: 120, height: 20)
            LoadingShimmer()
                .frame(width: 180, height: 20)
            LoadingShimmer()
                .frame(width: 90, height: 20)
            LoadingShimmer()
                .frame(width: 60, height: 20)
        }
    }
}
#endif
