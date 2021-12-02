//
//  PlistDataRepository.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Foundation
import Combine

protocol DetectorDataRepository {
    func loadClassDetectionData() -> AnyPublisher<[DetectionClassInfo], RepositoryLoadError>
}

struct PlistDataRepository: DetectorDataRepository {
    private let appState: Store<AppState>
    private var cancelBag = CancelBag()
    
    init(appState: Store<AppState>) {
        self.appState = appState
    }
    
    // MARK: - Interface implementations
    func loadClassDetectionData() -> AnyPublisher<[DetectionClassInfo], RepositoryLoadError> {
        loadUpPlist(name: ModelInfo.objectInfoPlistName)
            .decode(type: [DetectionClassInfo].self, decoder: PropertyListDecoder())
            .mapError { error in
                (error as? RepositoryLoadError) ?? .decodingError
            }.eraseToAnyPublisher()
    }
}

// MARK: - Helpers
extension PlistDataRepository {
    private func loadUpPlist(name: String) -> AnyPublisher<Data, RepositoryLoadError> {
        guard let path = Bundle.main.path(forResource: name, ofType: "plist") else {
            return Fail(error: .resourceDoesNotExist).eraseToAnyPublisher()
        }
        guard let data = FileManager.default.contents(atPath: path) else {
            return Fail(error: .couldNotLoadData).eraseToAnyPublisher()
        }
        return Just(data)
            .setFailureType(to: RepositoryLoadError.self)
            .eraseToAnyPublisher()
    }
}
