//
//  UserSettingsInteractor.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Combine
import UIKit

protocol UserSettingsLogic {
    func restoreToDefaults() -> AnyPublisher<Void, Never>
}

class UserSettingsInteractor: UserSettingsLogic {
    var appState: Store<AppState>
    
    init(appState: Store<AppState>) {
        self.appState = appState
    }
    
    // MARK: - Interface implementations
    func restoreToDefaults() -> AnyPublisher<Void,Never> {
        Future { [weak self] promise in
            self?.appState[\.savedState.liveDetection] = AppDefaults.isLiveDetectionEnabled
            self?.appState[\.savedState.annotationFrameColor] = AppDefaults.annotationFrameColor.hexString ?? ""
            self?.appState[\.savedState.annotationLabelSize] = AppDefaults.annotationLabelSize
            self?.appState[\.savedState.showAnnotationFrame] = AppDefaults.showAnnotationFrame
            self?.appState[\.savedState.showAnnotationLabel] = AppDefaults.showAnnotationLabel
            
            return promise(.success(()))
        }.eraseToAnyPublisher()
    }
}

// MARK: - Stub
class StubUserSettingsLogic: UserSettingsLogic {
    func restoreToDefaults() -> AnyPublisher<Void,Never> { Empty().eraseToAnyPublisher() }
}
