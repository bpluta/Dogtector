//
//  Clickable.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

enum TapableType {
    case link(isActive: Binding<Bool>, _ destination: () -> AnyView)
    case action(_ action: (() -> Void)?)
}

struct TapableModifier: ViewModifier {
    let type: TapableType
    
    func body(content: Content) -> some View {
        switch type {
        case .link(let isActive, let destination):
            Group {
                NavigationLink(isActive: isActive, destination: { destination() }) { EmptyView() }
                Button(action: { isActive.wrappedValue = true }) {
                    content
                }
            }
        case .action(let action):
            if let action = action {
                Button(action: action) {
                    content
                }
            } else {
                content
            }
        }
    }
}

extension View {
    func tapable(_ type: TapableType) -> some View {
        modifier(TapableModifier(type: type))
    }
}
