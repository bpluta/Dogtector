//
//  SystemEventsModels.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct ApplicationInfo: Codable {
    let appLanguage: String?
    let systemLanguage: String?
    let systemVersion: String?
    let deviceResolution: String?
    let appVersion: String?
    let deviceModel: String?
    let objectDecoderType: String?
}

enum SystemEventsError: Error {
    case encodingError
    case openError
}
