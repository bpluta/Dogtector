//
//  StrokedCapsuleButton.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct StrokedCapsuleButton: View {
    let text: String
    let color: Color = Theme.Color.white.color
    let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            Text(text)
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color, lineWidth: 2)
                )
        }).buttonStyle(.plain)
    }
}

#if DEBUG
struct StrokedCapsuleButtonPreview: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Spacer()
            Group {
                StrokedCapsuleButton(text: "CameraAccessButtonTitle".localized, action: {})
                StrokedCapsuleButton(text: "OpenSettingsButtonTitle".localized, action: {})
            }
            .frame(width: 200)
            Spacer()
        }.frame(maxWidth: .infinity)
        .background(Theme.Color.black.color)
    }
}
#endif
