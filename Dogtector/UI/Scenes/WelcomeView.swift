//
//  WelcomeView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

// MARK: - Models
extension WelcomeView {
    class ViewModel: ObservableObject {
        @Published var isCameraViewPresented: Bool = false
    }
}

// MARK: - View
struct WelcomeView: View {
    @Environment(\.injected) private var injected: DependencyContainer
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        VStack(spacing: isLargerDevice ? 20 : 10) {
            Spacer(minLength: 0)
            WelcomeLabel()
            Spacer(minLength: 0)
            InfoItems()
            Spacer(minLength: 0)
            ProceedButton()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, isLargerDevice ? 30 : 20)
        .padding(.vertical, 20)
        .background(backgroundGradient.ignoresSafeArea(edges: .all))
        .navigationBarHidden(true)
    }
    
    @ViewBuilder
    private func WelcomeLabel() -> some View {
        foregroundGradient
            .mask(
                VStack {
                    Text("WelcomeSceneWelcomeTitle".localized)
                        .font(.system(size: 28, weight: .regular))
                    Text("WelcomeSceneWelcomeAppName".localized)
                        .font(.system(size: 36, weight: .bold))
                }
            ).frame(height: 80)
    }
    
    @ViewBuilder
    private func InfoItems() -> some View {
        VStack(alignment: .leading, spacing: CGFloat(isLargerDevice ? 30 : 20)) {
            InfoSection(
                icon: Theme.Image.viewfinder,
                title: "WelcomeScemeLiveDetectionTitle".localized,
                description: "WelcomeScemeLiveDetectionDescrption".localized
            )
            InfoSection(
                icon: Theme.Image.magnifyingGlass,
                title: "WelcomeSceneDiscoverTitle".localized,
                description: "WelcomeSceneDiscoverDescription".localized
            )
            InfoSection(
                icon: Theme.Image.shield,
                title: "WelcomeScenePrivacyTitle".localized,
                description: "WelcomeScenePrivacyDescription".localized
            )
        }.padding(CGFloat(isLargerDevice ? 10 : 0))
    }
    
    @ViewBuilder
    private func ProceedButton() -> some View {
        Group {
            NavigationLink(
                isActive: $viewModel.isCameraViewPresented,
                destination: cameraView,
                label: { EmptyView() }
            )
            CapsuleButton(
                action: proceed,
                text: "GlobalContinue".localized,
                fill: Theme.Color.primaryDarker.color
            )
        }
    }
    
    private func cameraView() -> some View {
        CameraView()
            .inject(injected)
            .onAppear(perform: markWelcomeScreenAsDisplayed)
    }
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                Gradient.Stop(color: Theme.Color.primary.color, location: 0.0),
                Gradient.Stop(color: Theme.Color.primaryDarker.color, location: 0.3),
                Gradient.Stop(color: Theme.Color.black.color, location: 1.0)
            ]),
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    
    private var foregroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Theme.Color.primary.color, Theme.Color.primaryLighter.color]),
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }
    
    struct InfoSection: View {
        let icon: Image
        let title: String
        let description: String
        
        var body: some View {
            HStack(alignment: .center, spacing: 25) {
                icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(description)
                        .font(.system(size: 14, weight: .regular))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }.foregroundColor(Theme.Color.lightPink.color)
        }
    }
}

// MARK: - Helpers
extension WelcomeView {
    private func markWelcomeScreenAsDisplayed() {
        injected.appState[\.savedState.hasWelcomeScreenBeenDisplayed] = true
    }
    
    private func proceed() {
        UIApplication.setStatusBarStyle(.lightContent)
        viewModel.isCameraViewPresented = true
    }
}

#if DEBUG
struct WelcomeViewPreview: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
#endif
