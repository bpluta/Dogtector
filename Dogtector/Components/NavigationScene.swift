//
//  NavigationScene.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct NavigationScene<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        NavigationView {
            content
        }.accentColor(Theme.Color.primaryContrastive.color)
        .showNotification(NotificationSubject())
    }
}
