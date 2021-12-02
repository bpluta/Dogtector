//
//  ImageProcessingModels.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Foundation

enum ImageProcessingError: Error {
    case couldNotExtractData
    case libraryAccessNotAuthorized
    case saveError
    
    var notificationMessage: String {
        switch self {
        case .couldNotExtractData, .saveError:
            return "ImageProcessingSaveError".localized
        case .libraryAccessNotAuthorized:
            return "ImageProcessingNotAuthorizedError".localized
        }
    }
}
