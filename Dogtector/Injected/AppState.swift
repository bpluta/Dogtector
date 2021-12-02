//
//  AppState.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import UIKit
import SwiftUI

struct AppState {
    var userSettings = UserSettings()
    var permissions = Permissions()
    var detectorData = DetectorData()
    var system = System()
    var routing = ViewRouting()
    var savedState = SavedState()
}

extension AppState {
    struct Permissions: Equatable {
        var cameraAccess: Permission.Status = .unknown
        var photoLibaryAccess: Permission.Status = .unknown
    }
    
    static func permissionKeyPath(for permission: Permission) -> WritableKeyPath<AppState, Permission.Status> {
        let permissionsPath = \AppState.permissions
        switch permission {
        case .cameraAccess:
            return permissionsPath.appending(path: \.cameraAccess)
        case .photoLibraryAccess:
            return permissionsPath.appending(path: \.photoLibaryAccess)
        }
    }
}

extension AppState {
    struct ViewRouting: Equatable {
        var cameraView = CameraView.Routing()
    }
}

extension AppState {
    struct DetectorData: Equatable {
        var decoderType: ObjectDecoderType? = nil
        var classInfo: [DetectionClassInfo] = []
    }
}

extension AppState {
    struct System: Equatable {
        var isActive: Bool = true
        var isLowBatteryModeEnabled: Bool?
        var preferredStatusBarStyle: UIStatusBarStyle = .default
        var deviceOrientation: UIDeviceOrientation = .portrait
    }
}

extension AppState {
    struct SavedState {
        @AppStorage("isLiveDetectionEnabled") var liveDetection: Bool = AppDefaults.isLiveDetectionEnabled
        @AppStorage("annotationFrameColor") var annotationFrameColor: String = AppDefaults.annotationFrameColor.hexString ?? ""
        @AppStorage("annotationLabelSize") var annotationLabelSize: Double = AppDefaults.annotationLabelSize
        @AppStorage("shouldShowAnnotationFrame") var showAnnotationFrame: Bool = AppDefaults.showAnnotationFrame
        @AppStorage("shouldShowAnnotationLabel") var showAnnotationLabel: Bool = AppDefaults.showAnnotationLabel
        @AppStorage("hasWelcomeScreenBeenDisplayed") var hasWelcomeScreenBeenDisplayed: Bool = AppDefaults.hasWelcomeScreenBeenDisplayed
    }
}

extension AppState {
    struct UserSettings: Equatable {
        var shouldRespectLowBatteryMode: Bool = false
        var isLiveDetectionEnabled: Bool = false
    }
}

extension AppState.System {
    enum StatusBarStyle {
        case `default`
        case light
        case dark
    }
}

#if DEBUG
extension AppState {
    static var preview: AppState {
        var state = AppState()
        state.detectorData.classInfo = DetectionClassInfo.mocked
        return state
    }
}
#endif
