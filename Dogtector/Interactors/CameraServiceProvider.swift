//
//  CameraServiceProvider.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import UIKit
import AVFoundation
import Combine
import SwiftUI

protocol CameraServiceLogic {
    var captureStatusPublisher: AnyPublisher<CameraCaptureStatus, Never> { get }
    var imageOutputPublisher: AnyPublisher<CVPixelBuffer, Never> { get }
    var cameraZoomPublisher: AnyPublisher<CGFloat, Never> { get }
    
    func run(session: AVCaptureSession) -> AnyPublisher<SessionSetupInfo, CameraRunError>
    func configure(session: AVCaptureSession) -> AnyPublisher<SessionSetupInfo, CameraSetupError>
    func start() -> AnyPublisher<Void, CameraRunError>
    func stop() -> AnyPublisher<Void, CameraRunError>
    func takePhoto(withFlash: Bool) -> AnyPublisher<PhotoData, CameraRunError>
    func toggleTorch(to newValue: Bool) -> AnyPublisher<Void, CameraRunError>
    func setOutputOrientation(to orientation: OutputOrientation)
    func zoom(to zoomValue: CGFloat)
    func switchCamera()
}

class CameraServiceProvider: NSObject, CameraServiceLogic {
    private let appState: Store<AppState>
    
    private var session: AVCaptureSession?
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var bufferSize: CGSize = .zero
    private var standardZoomFactor: CGFloat = 1.0
    private var currentSetup: SessionSetupInfo?
    
    private var photoProcessingTime: CMTime?
    private var cancelBag: CancelBag = CancelBag()
    
    private let sessionQueue = DispatchQueue(label: "com.cameraServiceProvider.sessionQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    private var isConfigured = false
    private var isDeviceAuthorized: Bool { AVCaptureDevice.authorizationStatus(for: .video) == .authorized }
    
    private var imageOutputSubject = PassthroughSubject<CVPixelBuffer, Never>()
    private var capturePhotoSubject = PassthroughSubject<AVCapturePhoto, Never>()
    private var captureStatusSubject = PassthroughSubject<CameraCaptureStatus, Never>()
    private var cameraZoomSubject = CurrentValueSubject<CGFloat, Never>(1)
    
    // MARK: - Publishers
    var captureStatusPublisher: AnyPublisher<CameraCaptureStatus, Never> { captureStatusSubject.eraseToAnyPublisher() }
    var imageOutputPublisher: AnyPublisher<CVPixelBuffer, Never> { imageOutputSubject.eraseToAnyPublisher() }
    var cameraZoomPublisher: AnyPublisher<CGFloat, Never> { cameraZoomSubject.eraseToAnyPublisher() }
    
    init(appState: Store<AppState>) {
        self.appState = appState
    }
    
    // MARK: - Interface implementations
    func run(session: AVCaptureSession) -> AnyPublisher<SessionSetupInfo, CameraRunError> {
        configure(session: session)
            .mapError { error in
                CameraRunError(from: error)
            }.flatMap { [weak self] _ in
                self?.start() ?? Fail(error: .captureSessionFailure).eraseToAnyPublisher()
            }.map { [weak self] _ in
                self?.currentSetup
            }.unwrap(orThrow: CameraRunError.notConfigured)
            .mapError { ($0 as? CameraRunError) ?? .notConfigured }
            .eraseToAnyPublisher()
    }
    
    func configure(session: AVCaptureSession) -> AnyPublisher<SessionSetupInfo, CameraSetupError> {
        Future { [weak self] promise in
            guard let self = self else {
                return promise(.failure(.configurationFailed))
            }
            self.sessionQueue.async {
                let result = self.setupSession(for: session)
                return promise(result)
            }
        }.eraseToAnyPublisher()
    }
    
    func start() -> AnyPublisher<Void, CameraRunError> {
        Future { [weak self] promise in
            guard let self = self else {
                return promise(.failure(.captureSessionFailure))
            }
            self.sessionQueue.async {
                let result = self.startCapture()
                return promise(result)
            }
        }.eraseToAnyPublisher()
    }
    
    func stop() -> AnyPublisher<Void, CameraRunError> {
        Future { [weak self] promise in
            guard let self = self else {
                return promise(.failure(.captureSessionFailure))
            }
            self.sessionQueue.async {
                let result = self.stopCapture()
                return promise(result)
            }
        }.eraseToAnyPublisher()
    }
    
    func takePhoto(withFlash: Bool) -> AnyPublisher<PhotoData, CameraRunError> {
        Future { [weak self] promise in
            guard let self = self else {
                return promise(.failure(.captureSessionFailure))
            }
            var captureSettings: AVCapturePhotoSettings?
            self.capturePhotoSubject
                .first()
                .sink { capturedData in
                    guard let captureSettings = captureSettings else {
                        return promise(.failure(.captureSessionFailure))
                    }
                    let photoData = PhotoData(
                        capturedData: capturedData,
                        captureSettings: captureSettings
                    )
                    return promise(.success(photoData))
                }.store(in: self.cancelBag)
            self.sessionQueue.async {
                let result = self.capturePhoto(withFlash: withFlash)
                switch result {
                case .failure(let error):
                    return promise(.failure(error))
                case .success(let settings):
                    captureSettings = settings
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func toggleTorch(to newValue: Bool) -> AnyPublisher<Void, CameraRunError> {
        Future { [weak self] promise in
            guard let device = self?.videoDeviceInput?.device,
                  device.hasTorch,
                  let _ = try? device.lockForConfiguration()
            else {
                return promise(.failure(.captureSessionFailure))
            }
            device.torchMode = newValue ? .on : .off
            device.unlockForConfiguration()
            return promise(.success(()))
        }.eraseToAnyPublisher()
    }
    
    func zoom(to normalizedZoomValue: CGFloat) {
        guard let device = videoDeviceInput?.device else { return }
        let newZoomValue = normalizedZoomValue * standardZoomFactor
        setZoom(to: newZoomValue, for: device)
    }
    
    func switchCamera() {
        guard
            let device = videoDeviceInput?.device,
            let currentZoom = Double(exactly: device.videoZoomFactor)
        else { return }
        
        let availableZoomFactors = device.virtualDeviceSwitchOverVideoZoomFactors.compactMap { Double(exactly: $0) }
        let sortedZoomFactors = availableZoomFactors.sorted(by: <)
        var newZoom: Double = 1.0
        if let lastSwitchOverZoomFactor = availableZoomFactors.last, currentZoom > lastSwitchOverZoomFactor {
            newZoom = lastSwitchOverZoomFactor
        } else if let firstLargerZoomFactor = sortedZoomFactors.first(where: { currentZoom < $0 }) {
            newZoom = firstLargerZoomFactor
        }
        if newZoom == currentZoom {
            newZoom *= 2
        }
        setZoom(to: CGFloat(newZoom), for: device)
    }
    
    func setOutputOrientation(to orientation: OutputOrientation) {
        sessionQueue.sync {
            guard let captureConnection = self.videoDataOutput.connection(with: .video) else { return }
            if captureConnection.isVideoOrientationSupported {
                captureConnection.videoOrientation = AVCaptureVideoOrientation(from: orientation)
            }
        }
    }
}

// MARK: - Helpers
extension CameraServiceProvider {
    private func startCapture() -> Result<Void, CameraRunError> {
        guard let session = session else { return .failure(.captureSessionFailure) }
        switch runStatus {
        case .failure(let error):
            return .failure(error)
        case .success(let isRunning):
            if isRunning {
                return .success(())
            }
        }
        session.startRunning()
        guard session.isRunning else { return .failure(.captureSessionFailure) }
        return .success(())
    }
    
    private func stopCapture() -> Result<Void, CameraRunError> {
        guard let session = session else { return .failure(.captureSessionFailure) }
        switch runStatus {
        case .failure(let error):
            return .failure(error)
        case .success(let isRunning):
            if !isRunning {
                return .success(())
            }
        }
        session.stopRunning()
        guard !session.isRunning else { return .failure(.captureSessionFailure) }
        return .success(())
    }
    
    private func setZoom(to zoomValue: CGFloat, for device: AVCaptureDevice) {
        guard let _ = try? device.lockForConfiguration() else { return }
        let normalizedZoomValue = zoomValue / standardZoomFactor
        device.videoZoomFactor = zoomValue
        cameraZoomSubject.send(normalizedZoomValue)
        device.unlockForConfiguration()
    }
    
    private func getCaptureDevice() -> AVCaptureDevice? {
        let desiredDevices: [(AVCaptureDevice.DeviceType, AVCaptureDevice.Position)] = [
            (.builtInTripleCamera, .back),
            (.builtInDualWideCamera, .back),
            (.builtInDualCamera, .back),
            (.builtInWideAngleCamera, .back),
            (.builtInWideAngleCamera, .front)
        ]
        for (device, position) in desiredDevices {
            guard let device = AVCaptureDevice.default(device, for: AVMediaType.video, position: position) else { continue }
            return device
        }
        return nil
    }
    
    private func getStandardZoomFactor(of device: AVCaptureDevice) -> CGFloat {
        guard
            let wideAngleCameraIndex = device.constituentDevices.firstIndex(where: { $0.deviceType == .builtInWideAngleCamera })
        else { return 1.0 }
        
        let zoomFactorIndex = wideAngleCameraIndex - 1
        let availableZoomFactors = device.virtualDeviceSwitchOverVideoZoomFactors
        
        guard
            zoomFactorIndex >= 0 && zoomFactorIndex < availableZoomFactors.count,
            let zoomFactor = CGFloat(exactly: availableZoomFactors[zoomFactorIndex])
        else { return 1.0 }
        return zoomFactor
    }
    
    private func getZoomRange(of device: AVCaptureDevice) -> ClosedRange<CGFloat> {
        let standardZoomFactor = getStandardZoomFactor(of: device)
        let availableZoomFactors = [1.0] + device.virtualDeviceSwitchOverVideoZoomFactors.compactMap { CGFloat(exactly: $0) }
        
        let defaultZoomRange: ClosedRange<CGFloat> = AppDefaults.defaultMinimumCameraZoomScale...AppDefaults.maximumCameraZoomScale
        guard let minAvailableZoom = availableZoomFactors.min() else { return defaultZoomRange }
        let minZoomFactor = minAvailableZoom / standardZoomFactor
        
        return minZoomFactor...defaultZoomRange.upperBound
    }
    
    private func setupSession(for session: AVCaptureSession) -> Result<SessionSetupInfo, CameraSetupError> {
        guard isDeviceAuthorized else { return .failure(.notAuthorized) }
        self.session = session
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .inputPriority
        
        guard
            let videoDevice = getCaptureDevice(),
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            session.canAddInput(videoDeviceInput)
        else { return .failure(.configurationFailed) }
        
        session.addInput(videoDeviceInput)
        self.videoDeviceInput = videoDeviceInput
        
        guard session.canAddOutput(videoDataOutput) else {
            return .failure(.configurationFailed)
        }
        session.addOutput(videoDataOutput)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        videoDataOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
        let captureConnection = videoDataOutput.connection(with: .video)
        if captureConnection?.isVideoOrientationSupported ?? false {
            captureConnection?.videoOrientation = .portrait
        }
        captureConnection?.isEnabled = true
        do {
            try videoDevice.lockForConfiguration()
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice.activeFormat.formatDescription))
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            videoDevice.unlockForConfiguration()
        } catch {
            return .failure(.configurationFailed)
        }
        
        let standardZoomFactor = getStandardZoomFactor(of: videoDevice)
        self.standardZoomFactor = standardZoomFactor
        setZoom(to: standardZoomFactor, for: videoDevice)
        
        let zoomRange = getZoomRange(of: videoDevice)
        let sessionSetupInfo = SessionSetupInfo(zoomRange: zoomRange)
        currentSetup = sessionSetupInfo
        
        guard session.canAddOutput(photoOutput) else {
            return .failure(.configurationFailed)
        }
        session.addOutput(photoOutput)
        photoOutput.isHighResolutionCaptureEnabled = true
        photoOutput.maxPhotoQualityPrioritization = .quality
        
        isConfigured = true
        return .success(sessionSetupInfo)
    }
    
    private func capturePhoto(withFlash: Bool) -> Result<AVCapturePhotoSettings, CameraRunError> {
        if case .failure(let error) = runStatus {
            return .failure(error)
        }
        var photoSettings = AVCapturePhotoSettings()
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        photoSettings.flashMode = withFlash ? .on : .off
        photoSettings.isHighResolutionPhotoEnabled = true
        if let formatType = photoSettings.__availablePreviewPhotoPixelFormatTypes.first  {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: formatType]
        }
        photoSettings.photoQualityPrioritization = .quality
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
        
        return .success(photoSettings)
    }
    
    private var runStatus: Result<Bool, CameraRunError> {
        guard let session = session else { return .failure(.captureSessionFailure) }
        guard !session.isRunning else { return .success(true) }
        guard isDeviceAuthorized else { return .failure(.notAuthorized) }
        guard isConfigured else { return .failure(.notConfigured) }
        return .success(false)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraServiceProvider: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        photoProcessingTime = resolvedSettings.photoProcessingTimeRange.start + resolvedSettings.photoProcessingTimeRange.duration
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        captureStatusSubject.send(.capturing)
        guard let photoProcessingTime = photoProcessingTime else { return }
        if photoProcessingTime > CMTime(seconds: 1, preferredTimescale: 1) {
            captureStatusSubject.send(.processing)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        capturePhotoSubject.send(photo)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        captureStatusSubject.send(.captured)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraServiceProvider: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        imageOutputSubject.send(pixelBuffer)
    }
}

// MARK: - Stub
class StubCameraServiceLogic: CameraServiceLogic {
    var captureStatusPublisher: AnyPublisher<CameraCaptureStatus, Never> { Empty().eraseToAnyPublisher() }
    var imageOutputPublisher: AnyPublisher<CVPixelBuffer, Never> { Empty().eraseToAnyPublisher() }
    var cameraZoomPublisher: AnyPublisher<CGFloat, Never> { Empty().eraseToAnyPublisher() }
    
    func run(session: AVCaptureSession) -> AnyPublisher<SessionSetupInfo, CameraRunError> {
        Empty().eraseToAnyPublisher()
    }
    
    func configure(session: AVCaptureSession) -> AnyPublisher<SessionSetupInfo, CameraSetupError> {
        Empty().eraseToAnyPublisher()
    }
    
    func start() -> AnyPublisher<Void, CameraRunError> {
        Empty().eraseToAnyPublisher()
    }
    
    func stop() -> AnyPublisher<Void, CameraRunError> {
        Empty().eraseToAnyPublisher()
    }
    
    func takePhoto(withFlash: Bool) -> AnyPublisher<PhotoData, CameraRunError> {
        Empty().eraseToAnyPublisher()
    }
    
    func toggleTorch(to newValue: Bool) -> AnyPublisher<Void, CameraRunError> {
        Empty().eraseToAnyPublisher()
    }
    
    func setOutputOrientation(to orientation: OutputOrientation) { }
    
    func zoom(to zoomValue: CGFloat) { }
    
    func switchCamera() { }
}
