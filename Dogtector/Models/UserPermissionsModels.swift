//
//  UserPermissionsModels.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Photos

enum Permission {
    case cameraAccess
    case photoLibraryAccess
    
    enum Status: Equatable {
        case unknown
        case notDetermined
        case granted
        case denied
        case restricted
        case limited
        
        var isAccesable: Bool {
            [.granted, .limited].reduce(false, { self == $1 || $0 })
        }
    }
}

extension Permission.Status {
    init(from status: AVAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .authorized:
            self = .granted
        @unknown default:
            self = .unknown
        }
    }
    
    init(from status: PHAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .authorized:
            self = .granted
        case .limited:
            self = .limited
        @unknown default:
            self = .unknown
        }
    }
}
