//
//  InformationScreen.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct InformationScreen<Content: View>: View {
    private let content: Content
    private let title: String
    private let icon: Image
    private let gradient: Gradient
    
    private let buttonTitle: String
    private let buttonAction: (() -> Void)?
    private let dismissAction: (() -> Void)?
    
    init(title: String,
         icon: Image,
         gradient: Gradient,
         buttonTitle: String = "GlobalClose".localized,
         buttonAction: (() -> Void)? = nil,
         dismissAction: (() -> Void)? = nil,
         @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.dismissAction = dismissAction
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: isLargerDevice ? 20 : 0) {
            VStack(spacing: isLargerDevice ? 10 : 5) {
                Spacer(minLength: 0)
                Icon()
                    .frame(height: isLargerDevice ? 140 : 100)
                Title(text: title)
                content
            }
            ActionButton()
        }.padding(.horizontal, 30)
        .padding(.bottom, isLargerDevice ? 20 : 10)
        .navigationBarTitle(Text(""), displayMode: .inline)
    }
    
    private func BackgroundGradient() -> LinearGradient {
        LinearGradient(
            gradient: gradient,
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }
    
    @ViewBuilder
    private func Icon() -> some View {
        ZStack {
            BackgroundGradient().mask(
                RoundedRectangle(cornerRadius: isLargerDevice ? 30 : 20)
                    .aspectRatio(1.0, contentMode: .fit)
            )
            icon
                .resizable()
                .scaledToFit()
                .foregroundColor(Theme.Color.white.color)
                .padding(isLargerDevice ? 30 : 20)
        }.aspectRatio(1.0, contentMode: .fit)
    }
    
    @ViewBuilder
    private func Title(text: String) -> some View {
        TitleText(text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isLargerDevice ? 20 : 10)
            .foregroundColor(Theme.Color.clear.color)
            .overlay(
                BackgroundGradient()
                    .mask(TitleText(text))
            )
    }
    
    @ViewBuilder
    private func TitleText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: isLargerDevice ? 30 : 22, weight: .bold))
            .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    private func Label(text: String) -> some View {
        Text(text)
            .font(.system(size: isLargerDevice ? 14 : 13))
            .multilineTextAlignment(.center)
            .padding(.horizontal, isLargerDevice ? 20 : 0)
    }
    
    @ViewBuilder
    private func ActionButton() -> some View {
        CapsuleButton(
            action: buttonAction ?? dismiss,
            text: buttonTitle,
            fill: BackgroundGradient(),
            padding: isLargerDevice ? 20 : 15
        )
    }
}

extension InformationScreen {
    private var dismiss: () -> Void {
        dismissAction ?? {}
    }
}

#if DEBUG
struct InformationScreenPreview: PreviewProvider {
    @State private static var isLiveDetectionEnabled: Bool = true
    static var previews: some View {
        InformationScreen(
            title: "Lorem ipsum",
            icon: Theme.Image.viewfinder,
            gradient: Gradient(colors: [
                Theme.Color.purple.color,
                Theme.Color.blue.color
            ])
        ) {
            Group {
                Text("dolor sit amet")
                    .font(.system(size: 14))
                Spacer()
            }
        }
    }
}
#endif
