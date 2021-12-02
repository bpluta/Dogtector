//
//  CameraShutterButton.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct CameraShutterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeIn(duration: 0.1), value: configuration.isPressed)
    }
}

struct CameraShutterButton: View {
    var body: some View {
        Circle()
            .fill(Theme.Color.white.color)
            .aspectRatio(1.0, contentMode: .fit)
            .padding(15)
            .overlay(
                Circle().stroke(Theme.Color.white.color, lineWidth: 5)
                    .padding(10)
            )
            .overlay(
                Circle().stroke(Theme.Color.white.color, lineWidth: 5).opacity(0.3)
                    .padding(2.5)
            )
    }
}

#if DEBUG
struct CameraShutterButtonPreview: PreviewProvider {
    static var previews: some View {
            CameraShutterButton()
            .background(Theme.Color.black.color)
                .frame(width: 90)
                .previewLayout(.sizeThatFits)
    }
}
#endif
