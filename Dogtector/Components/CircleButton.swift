//
//  CircleButton.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}

struct CircleButton<Content: View>: View {
    let scaleFactor: CGFloat
    let content: () -> Content
    
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        GeometryReader { geometry in
            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
                .cornerRadius(geometry.size.width / 2)
                .aspectRatio(1.0, contentMode: .fit)
                .overlay(
                    content()
                        .frame(width: geometry.size.width * scaleFactor)
                        .padding(geometry.size.width / 4)
                )
        }.aspectRatio(1.0, contentMode: .fit)
        .opacity(isEnabled ? 1 : 0.6)
    }
}

#if DEBUG
struct CircleButtonPreview: PreviewProvider {
    static var previews: some View {
        CircleButton(scaleFactor: 0.5) {
            Theme.Image.pictures
                .resizable()
                .scaledToFit()
                .foregroundColor(Theme.Color.white.color)
        }
        .frame(width: 80)
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
#endif
