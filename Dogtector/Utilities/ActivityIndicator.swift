//
//  ActivityIndicator.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct AtivityIndicator: View {
    var body: some View {
        ZStack {
            Background()
            Indicator()
        }
    }
    
    @ViewBuilder
    private func Background() -> some View {
        Color.black.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
    }
    
    @ViewBuilder
    private func Indicator() -> some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: Theme.Color.white.color))
            .scaleEffect(1.5, anchor: .center)
    }
}


struct ActivityIndicatorModifier: ViewModifier {
    let isPresented: Binding<Bool>
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented.wrappedValue {
                AtivityIndicator()
            }
        }
    }
}

extension View {
    func activityIndicator(isPresented: Binding<Bool>) -> some View {
        self.modifier(ActivityIndicatorModifier(isPresented: isPresented))
    }
}
