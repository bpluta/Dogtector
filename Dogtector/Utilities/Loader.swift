//
//  Loader.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import Combine

// MARK: - Models
extension Loader {
    class ViewModel: ObservableObject {
        var isPresented: Binding<Bool>
        @Published var didAppear: Bool = false
        
        init(isPresented: Binding<Bool>) {
            self.isPresented = isPresented
        }
    }
}

// MARK: - View
struct Loader: View {
    @ObservedObject var viewModel: ViewModel
    
    init(isPresented: Binding<Bool>) {
        viewModel = ViewModel(isPresented: isPresented)
    }

    var body: some View {
        if viewModel.isPresented.wrappedValue {
            ZStack {
                Background()
                LoaderView()
            }.onAppear(perform: triggerAnimation)
        }
    }
    
    @ViewBuilder
    private func Background() -> some View {
        Color.black.opacity(viewModel.didAppear ? 0.5 : 0)
            .edgesIgnoringSafeArea(.all)
    }
    
    @ViewBuilder
    private func LoaderView() -> some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Theme.Color.primary.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
            .rotationEffect(Angle(degrees: viewModel.didAppear ? 360: 0))
            .animation(.linear(duration: 0.7).repeatForever(autoreverses: false))
            .frame(width: 60, height: 60, alignment: .center)
    }
}

// MARK: - Helpers
extension Loader {
    func triggerAnimation() {
        DispatchQueue.main.async {
            withAnimation {
                self.viewModel.didAppear = true
            }
        }
    }
}

// MARK: - View modifier
struct LoaderModifier: ViewModifier {
    let isPresented: Binding<Bool>
    
    func body(content: Content) -> some View {
        ZStack {
            content
            Loader(isPresented: isPresented)
        }
    }
}

extension View {
    func loader(isPresented: Binding<Bool>) -> some View {
        self.modifier(LoaderModifier(isPresented: isPresented))
    }
}

#if DEBUG
struct LoaderPreview: PreviewProvider {
    @State static var isPresented: Bool = true
    static var previews: some View {
        Loader(isPresented: $isPresented)
    }
}
#endif
