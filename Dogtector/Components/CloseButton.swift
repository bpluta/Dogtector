//
//  CloseButton.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct CloseButton: View {
    var body: some View {
        Circle()
            .foregroundColor(Theme.Color.adaptiveGray.color)
            .frame(width: 30, height: 30)
            .overlay(
                Theme.Image.xmark
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(Theme.Color.adaptiveDarkerGray.color)
                    .padding(8)
            )
    }
}

// MARK: - View Modifier
struct NavigationViewWithCloseButton<LeadingItem: View>: ViewModifier {
    @Environment(\.modalMode) private var modalMode
    
    let leadingItem: () -> LeadingItem
    
    func body(content: Content) -> some View {
        content
            .navigationBarItems(leading: leadingItem(), trailing: DismissButton())
    }
    
    @ViewBuilder
    private func DismissButton() -> some View {
        Button(action: dismiss) {
            CloseButton()
                .frame(width: 44, height: 44, alignment: .trailing)
        }
    }
    
    private func dismiss() {
        modalMode.wrappedValue = false
    }
}

extension View {
    func navigationWithCloseButton<Content: View>(leadingItem: @escaping () -> Content) -> some View {
        modifier(NavigationViewWithCloseButton(leadingItem: leadingItem))
    }
    
    func navigationWithCloseButton() -> some View {
        modifier(NavigationViewWithCloseButton(leadingItem: { EmptyView() }))
    }
}


#if DEBUG
struct CloseButtonPreview: PreviewProvider {
    static var previews: some View {
        CloseButton()
    }
}
#endif
