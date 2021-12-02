//
//  DependencyContainer.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import Combine

class DependencyContainer: EnvironmentKey {
    let appState: Store<AppState>
    let interactors: InteractorContainer
    
    init(appState: Store<AppState>, interactors: InteractorContainer) {
        self.appState = appState
        self.interactors = interactors
    }
    
    convenience init(appState: AppState, interactors: InteractorContainer) {
        self.init(appState: Store<AppState>(appState), interactors: interactors)
    }
    
    static var defaultValue: DependencyContainer { Self.default }
    
    private static let `default` = DependencyContainer(appState: AppState(), interactors: .stub)
}

#if DEBUG
extension DependencyContainer {
    static var preview: DependencyContainer {
        DependencyContainer(appState: AppState.preview, interactors: .stub)
    }
}
#endif

extension EnvironmentValues {
    var injected: DependencyContainer {
        get { self[DependencyContainer.self] }
        set { self[DependencyContainer.self] = newValue }
    }
}

extension View {
    func inject(_ appState: AppState, _ interactors: DependencyContainer.InteractorContainer) -> some View {
        let container = DependencyContainer(appState: appState, interactors: interactors)
        return inject(container)
    }
    
    func inject(_ container: DependencyContainer) -> some View {
        environment(\.injected, container)
    }
}
