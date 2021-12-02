//
//  CapsuleButton.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct CapsuleButton<FillType: ShapeStyle>: View {
    var action: () -> Void
    var text: String
    var fill: FillType
    var padding: CGFloat = 20
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.Color.white.color)
            }.padding(.vertical, padding)
            .padding(.horizontal, padding * 3 / 2)
            .frame(minWidth: 200)
            .background(Capsule().fill(fill))
        }.buttonStyle(.plain)
    }
}

#if DEBUG
struct CapsuleButtonPreview: PreviewProvider {
    static var previews: some View {
        CapsuleButton(action: {}, text: "Lorem ipsum", fill: Theme.Color.red.color)
    }
}
#endif
