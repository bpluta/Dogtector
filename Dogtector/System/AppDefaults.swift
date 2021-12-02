//
//  AppDefaults.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct AppDefaults {
    static let isLiveDetectionEnabled: Bool = true
    static let annotationFrameColor: UIColor = Theme.Color.yellow
    static let annotationLabelSize: Double = 1.0
    static let showAnnotationFrame: Bool = true
    static let showAnnotationLabel: Bool = true
    static let hasWelcomeScreenBeenDisplayed: Bool = false
    
    static let minimumImageZoomScale: CGFloat = 1
    static let maximumImageZoomScale: CGFloat = 5
    
    static let defaultMinimumCameraZoomScale: CGFloat = 1
    static let maximumCameraZoomScale: CGFloat = 10
    
    static let previewAspectRatio: CGFloat = 16.0 / 9.0
    
    static let metalDevice = MTLCreateSystemDefaultDevice()
    
    static let appName = "GlobalAppName".localized
    static let appIconBundleName = "app_icon"
    static let appStoreURL = URL(string: "https://apps.apple.com/us/app/dogtector/id1597156924")
    
    static let colorPickerColors: [Color] = [
        Theme.Color.red.color,
        Theme.Color.orange.color,
        Theme.Color.yellow.color,
        Theme.Color.green.color,
        Theme.Color.blue.color,
        Theme.Color.purple.color,
        Theme.Color.black.color,
        Theme.Color.gray.color,
        Theme.Color.white.color
    ]
}
