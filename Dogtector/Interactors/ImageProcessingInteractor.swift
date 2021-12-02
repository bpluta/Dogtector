//
//  ImageProcessingInteractor.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Foundation
import Combine
import SwiftUI
import Photos

protocol ImageProcessingLogic {
    func save(image: UIImage) -> AnyPublisher<Void, ImageProcessingError>
}

// MARK: - Interface implementations
class ImageProcessingInteractor: NSObject, ImageProcessingLogic {
    func save(image: UIImage) -> AnyPublisher<Void, ImageProcessingError> {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return Fail<Void, ImageProcessingError>(error: .couldNotExtractData).eraseToAnyPublisher()
        }
        return saveImage(imageData: imageData, uniformTypeIdentifier: AVFileType.jpg.rawValue)
    }
}

// MARK: - Helpers
extension ImageProcessingInteractor {
    private func saveImage(imageData: Data, uniformTypeIdentifier: String?) -> AnyPublisher<Void, ImageProcessingError> {
        Future { promise in
            let accessStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            guard accessStatus == .authorized || accessStatus == .limited else {
                return promise(.failure(.libraryAccessNotAuthorized))
            }
            
            PHPhotoLibrary.shared().performChanges {
                let options = PHAssetResourceCreationOptions()
                let creationRequest = PHAssetCreationRequest.forAsset()
                options.uniformTypeIdentifier = uniformTypeIdentifier
                creationRequest.addResource(with: .photo, data: imageData, options: options)
            } completionHandler: { success, error in
                guard success else {
                    return promise(.failure(.saveError))
                }
                return promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - Stub
class StubImageProcessingLogic: ImageProcessingLogic {
    func save(image: UIImage) -> AnyPublisher<Void, ImageProcessingError> {
        Empty().eraseToAnyPublisher()
    }
}
