//
//  CameraViewModels.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct PreviewedImage {
    let image: UIImage?
    var detections: [Observation]?
}

enum PreviewMode {
    case empty
    case live
    case captured
    case picked
    case noPermission
}

struct ZoomState {
    var oldMagnitude: CGFloat = 1
    var oldZoomValue: CGFloat = 1
    var zoomRange: ClosedRange<CGFloat> = 1...1
    var initialZoomValue: CGFloat?
}

extension CameraView {
    struct Routing: Equatable {
        var predictionDetailsSheet: Bool = false
        var allPredictionsListSheet: Bool = false
        var imagePickerSheet: Bool = false
        var lowPowerModeSheet: Bool = false
//        var donationSheet: Bool = false
    }
    
    enum SwitchedOperation {
        case liveDetection
        case flash
        case showPreviewSettings
        
        var path: ReferenceWritableKeyPath<CameraView.ViewModel, Bool> {
            switch self {
            case .liveDetection:
                return \.isLiveDetecitonEnabled
            case .flash:
                return \.isFlashEnabled
            case .showPreviewSettings:
                return \.areDetectionPreviewSettingsDisplayed
            }
        }
        
        var savedStatePath: ReferenceWritableKeyPath<AppState, Bool>? {
            switch self {
            case .liveDetection:
                return \.savedState.liveDetection
            default: return nil
            }
        }
        
        func description(forValue value: Bool) -> String? {
            switch self {
            case .liveDetection:
                return value ? "LiveDetectionHasBeenEnabled".localized : "LiveDetectionHasBeenDisabled".localized
            case .flash:
                return value ? "FlashHasBeenEnabled".localized : "FlashHasBeenDisabled".localized
            case .showPreviewSettings:
                return nil
            }
        }
    }
}
