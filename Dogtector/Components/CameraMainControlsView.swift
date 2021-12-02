//
//  CameraMainControls.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct CameraMainControls: ViewModifier {
    func body(content: Content) -> some View {
        content.frame(height: 100)
    }
}

extension CameraMainControls {
    struct ButtonView: Identifiable, View {
        enum ButtonMode {
            case imageOption(Image)
            case zoom(Double)
            case shutter
        }
        
        @Environment(\.isEnabled) private var isEnabled
        
        let id = UUID()
        let mode: ButtonMode
        let tapAction: TapableType
        
        var body: some View {
            buttonContent
                .frame(width: buttonSize)
                .tapable(tapAction)
                .applyStyle(for: mode)
                .simultaneousGesture(longPressGesture)
        }
        
        @ViewBuilder
        private var buttonContent: some View {
            switch mode {
            case .imageOption(let image):
                CircleButton(scaleFactor: 0.5) {
                    image
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(foregroundColor)
                }.disabled(!isEnabled)
            case .zoom(let value):
                CircleButton(scaleFactor: 1.0) {
                    HStack(spacing: 2) {
                        Text(String(format: "%.2g", value))
                            .font(.system(size: 20, weight: .bold))
                            .lineLimit(1)
                            .foregroundColor(foregroundColor)
                        Theme.Image.xmark
                            .resizable()
                            .font(Font.title.weight(.semibold))
                            .foregroundColor(foregroundColor)
                            .frame(width: 9, height: 9)
                    }
                }.disabled(!isEnabled)
            case .shutter:
                CameraShutterButton()
            }
        }
        
        private var foregroundColor: Color {
            isEnabled ? Theme.Color.white.color : Theme.Color.white.color.opacity(0.5)
        }
        
        private var buttonSize: CGFloat {
            switch mode {
            case .imageOption, .zoom: return 60
            case .shutter: return 100
            }
        }
        
        private var longPressGesture: some Gesture {
            LongPressGesture(minimumDuration: 0.1)
                .onEnded { _ in hapticFeedback() }
        }
        
        private func hapticFeedback() {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

fileprivate extension View {
    @ViewBuilder
    func applyStyle(for mode: CameraMainControls.ButtonView.ButtonMode) -> some View {
        switch mode {
        case .imageOption, .zoom:
                self.buttonStyle(CameraOptionsButtonStyle())
        case .shutter:
            self.buttonStyle(CameraShutterButtonStyle())
        }
    }
}

#if DEBUG
struct CameraMainControlsPreview: PreviewProvider {
    static var previews: some View {
        HStack {
            Spacer()
            CameraMainControls.ButtonView(
                mode: .imageOption(Theme.Image.list),
                tapAction: .action({ })
            )
            Spacer()
            CameraMainControls.ButtonView(
                mode: .imageOption(Theme.Image.slashedEye),
                tapAction: .action({ })
            )
            Spacer()
            CameraMainControls.ButtonView(
                mode: .imageOption(Theme.Image.save),
                tapAction: .action({ })
            )
            Spacer()
        }
        .modifier(CameraMainControls())
        .background(Color.gray)
    }
}
#endif
