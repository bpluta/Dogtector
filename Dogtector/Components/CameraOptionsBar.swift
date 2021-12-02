//
//  CameraOptionsBar.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct CameraOptionsButtonStyle: ButtonStyle {
    private let withOverlay: Bool
    
    init(withOverlay: Bool = true) {
        self.withOverlay = withOverlay
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.2 : 1.0)
            .animation(.easeIn(duration: 0.1), value: configuration.isPressed)
            .overlay(withOverlay ? DroppedOverlay(isPressed: configuration.isPressed) : nil)
    }
    
    @ViewBuilder
    private func DroppedOverlay(isPressed: Bool) -> some View {
        Theme.Color.gray.color
            .opacity(isPressed ? 0.5 : 0.0)
            .blendMode(.multiply)
            .clipShape(Circle())
    }
}

struct CameraOptionsBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 15)
            .padding(.vertical, 7)
            .background(Theme.Color.black.color.opacity(0.3))
    }
}

extension CameraOptionsBar {
    struct ButtonView: Identifiable, View {
        enum ContentMode {
            case image(image: Image, scale: CGFloat = 1.0)
            case strikethroughImage(image: Image, scale: CGFloat = 1.0, strikethroughScale: CGFloat = 1.0, isStrikethroughDisplayed: Bool, weight: Font.Weight = .regular)
            case text(text: Text)
        }
        
        let id = UUID()
        
        let tapAction: TapableType
        let content: ContentMode
        
        @Environment(\.isEnabled) private var isEnabled
        
        var body: some View {
            buildContent()
                .foregroundColor(foregroundColor)
                .padding(15)
                .tapable(tapAction)
                .applyStyle(for: content)
                .opacity(isEnabled ? 1.0 : 0.5)
        }
        
        @ViewBuilder
        private func buildContent() -> some View {
            switch content {
            case .image(let image, let scale):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25 * scale, height: 25 * scale, alignment: .center)
            case .strikethroughImage(let image, let scale, let strikethroughScale, let isStrikethroughDisplayed, let weight):
                image
                    .addStrikethrough(isStrikethroughDisplayed: isStrikethroughDisplayed, strikethroughScale: strikethroughScale)
                    .font(Font.title.weight(weight))
                    .frame(width: 25 * scale, height: 25 * scale, alignment: .center)
            case .text(let text):
                text
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        
        private var foregroundColor: Color {
            isEnabled ? Theme.Color.white.color : Theme.Color.lightGray.color
        }
    }
}

fileprivate extension View {
    @ViewBuilder
    func applyStyle(for mode: CameraOptionsBar.ButtonView.ContentMode) -> some View {
        switch mode {
            case .image, .strikethroughImage:
                self.buttonStyle(CameraOptionsButtonStyle())
            case .text:
                self.buttonStyle(CameraOptionsButtonStyle(withOverlay: false))
        }
    }
}

#if DEBUG
struct CameraOptionsBarPreview: PreviewProvider {
    static var previews: some View {
        ZStack {
            Image("samoyed")
                .resizable()
                .scaledToFit()
                .frame(width: 375)
            HStack {
                CameraOptionsBar.ButtonView(
                    tapAction: .action({ }),
                    content: .image(image: Theme.Image.chevronLeft)
                )
                Spacer()
                CameraOptionsBar.ButtonView(
                    tapAction: .action({ }),
                    content: .text(text: Text("CameraDetectionNotFound".localized))
                )
                Spacer()
                CameraOptionsBar.ButtonView(
                    tapAction: .action({ }),
                    content: .image(image: Theme.Image.more)
                )
            }.modifier(CameraOptionsBar())
        }
        .frame(width: 375)
    }
}
#endif
