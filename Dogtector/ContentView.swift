//
//  ContentView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct ContentView: View {
    private let container: DependencyContainer
    @State private var contentDidLoad: Bool = false
    
    init(container: DependencyContainer) {
        self.container = container
    }
    
    private var hasWelcomeScreenBeenDisplayed: Bool {
        container.appState[\.savedState.hasWelcomeScreenBeenDisplayed]
    }
    
    var body: some View {
        NavigationScene {
            ZStack {
                AppContent()
                    .inject(container)
                SplashScreen()
            }
        }.navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: hideSplashScreen)
    }
    
    @ViewBuilder
    private func AppContent() -> some View {
        if hasWelcomeScreenBeenDisplayed {
            CameraView()
        } else {
            WelcomeView()
        }
    }
    
    @ViewBuilder
    private func SplashScreen() -> some View {
        if !contentDidLoad {
            Theme.Color.black.color
                .transition(.asymmetric(insertion: .identity, removal: .opacity))
        }
    }
    
    private func hideSplashScreen() {
        DispatchQueue.main.async {
            withAnimation { contentDidLoad = true }
        }
    }
}
