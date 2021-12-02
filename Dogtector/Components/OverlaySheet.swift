//
//  OverlaySheet.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import Foundation

struct OverlaySheet<Content: View>: View {
    @GestureState private var dragState: CGSize = .zero
    @State private var isDragging: Bool = false
    
    private var isPresented: Binding<Bool>
    private var content: Content
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
            VStack {
                Capsule()
                    .foregroundColor(Theme.Color.gray.color)
                    .frame(width: 50, height: 5, alignment: .center)
                content
            }
            .padding(.top, 10)
            .padding(.bottom, -dragState.height)
            .frame(maxWidth: .infinity)
            .padding(.bottom, bottomSafeAreaHeight)
            .background(Theme.Color.listCell.color)
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .offset(y: bottomSafeAreaHeight)
            .gesture(dragGesture)
            .transition(.move(edge: .bottom))
            .animation(.easeOut(duration: 0.2))
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragState) { value, state, transaction in
                state = value.translation
            }
            .onEnded { value in
                guard value.translation.height > 100 else { return }
                hideSelf()
            }
    }
}

extension OverlaySheet {
    private var bottomSafeAreaHeight: CGFloat {
        UIApplication.shared.windows.first { $0.isKeyWindow }?.safeAreaInsets.bottom ?? 0
    }
    
    private func hideSelf() {
        isPresented.wrappedValue = false
    }
}

#if DEBUG
struct OverlaySheetPreview: PreviewProvider {
    @ObservedObject private static var settings = DetectionPreviewSettings()
    @State private static var isLiveDetectionEnabled = true
    
    static var previews: some View {
        VStack {
            Spacer()
            OverlaySheet(isPresented: .constant(true)) {
                DetectionPreviewSettingsView(
                    settings: settings,
                    isLiveDetectionEnabled: $isLiveDetectionEnabled
                )
            }.offset(y: 45)
        }
    }
}
#endif
