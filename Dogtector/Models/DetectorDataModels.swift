//
//  DetectorDataModels.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Foundation

enum RepositoryLoadError: Error {
    case decodingError
    case couldNotLoadData
    case resourceDoesNotExist
}
