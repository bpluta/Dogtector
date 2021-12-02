//
//  CameraServiceProviderModels.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import AVFoundation

protocol ImageData {
    var image: UIImage? { get }
    var size: CGSize? { get }
    var buffer: CVPixelBuffer? { get }
}

// MARK: - Structs
struct PhotoData: ImageData {
    let capturedData: AVCapturePhoto
    let captureSettings: AVCapturePhotoSettings
    
    var image: UIImage? {
        guard let data = capturedData.fileDataRepresentation() else { return nil }
        return UIImage(data: data)
    }
    
    var size: CGSize? {
        image?.size
    }
    
    var buffer: CVPixelBuffer? {
        image?.pixelBuffer
    }
    
    init(capturedData: AVCapturePhoto, captureSettings: AVCapturePhotoSettings) {
        self.capturedData = capturedData
        self.captureSettings = captureSettings
    }
}

struct PickedImage: ImageData {
    var image: UIImage?
    
    var buffer: CVPixelBuffer? {
        image?.pixelBuffer
    }
    
    var size: CGSize? {
        image?.size
    }
}

struct SessionSetupInfo {
    let zoomRange: ClosedRange<CGFloat>
}


// MARK: - Enums
enum CameraCaptureStatus {
    case capturing
    case processing
    case captured
}

enum CameraSetupError: Error {
    case notAuthorized
    case configurationFailed
}

enum OutputOrientation: String {
    case portarait
    case landscapeLeft
    case landscapeRight
    case upsideDown
    
    init?(from orientation: UIDeviceOrientation) {
        switch orientation {
        case .portrait:
            self = .portarait
        case .portraitUpsideDown:
            self = .upsideDown
        case .landscapeLeft:
            self = .landscapeLeft
        case .landscapeRight:
            self = .landscapeRight
        case .unknown, .faceUp, .faceDown:
            return nil
        @unknown default:
            return nil
        }
    }
}

enum CameraRunError: Error {
    case notAuthorized
    case notConfigured
    case captureSessionFailure
    
    init(from setupError: CameraSetupError) {
        switch setupError {
        case .notAuthorized:
            self = .notAuthorized
        case .configurationFailed:
            self = .notConfigured
        }
    }
    
    var message: String {
        switch self {
        case .notAuthorized:
            return "CameraNotAuthorizedError".localized
        case .notConfigured, .captureSessionFailure:
            return "CameraTakeImageError".localized
        }
    }
}

// MARK: - Extensions
extension AVCaptureVideoOrientation {
    init(from orientation: OutputOrientation) {
        switch orientation {
        case .portarait:
            self = .portrait
        case .landscapeLeft:
            self = .landscapeRight
        case .landscapeRight:
            self = .landscapeLeft
        case .upsideDown:
            self = .portraitUpsideDown
        }
    }
}

extension CGImagePropertyOrientation {
    init(from orientation: OutputOrientation) {
        switch orientation {
        case .portarait:
            self = .up
        case .landscapeLeft:
            self = .left
        case .landscapeRight:
            self = .right
        case .upsideDown:
            self = .down
        }
    }
}
