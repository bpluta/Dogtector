//
//  UserPermissionsInteractor.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Foundation
import AVFoundation
import Photos
import Combine

protocol UserPermissionsLogic {
    func resolveStatus(for permission: Permission) -> AnyPublisher<Permission.Status,Never>
    func request(permission: Permission)
    func request(for permission: Permission) -> AnyPublisher<Permission.Status,Never>
}

class UserPermissionsInteractor: UserPermissionsLogic {
    private let appState: Store<AppState>
    private var cancelBag = CancelBag()
    
    private let permissionQueue = DispatchQueue(label: "com.userPermissionsInteractor.permissionQueue")
    
    init(appState: Store<AppState>) {
        self.appState = appState
    }
    
    // MARK: - Interface implementations
    func resolveStatus(for permission: Permission) -> AnyPublisher<Permission.Status,Never> {
        let keyPath = AppState.permissionKeyPath(for: permission)
        let currentStatus = appState[keyPath]
        guard currentStatus == .unknown else {
            return Just(currentStatus).eraseToAnyPublisher()
        }
        return Future { [weak self] promise in
            self?.permissionQueue.async {
                let resolveAction: (Permission.Status) -> Void = { status in
                    self?.appState[keyPath] = status
                    promise(.success(status))
                }
                switch permission {
                case .cameraAccess:
                    self?.getCameraAccessPermissionStatus(onResolve: resolveAction)
                case .photoLibraryAccess:
                    self?.getPhotoLibraryPermisssionStatus(onResolve: resolveAction)
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func request(permission: Permission) {
        request(for: permission)
            .sink { _ in }
            .store(in: cancelBag)
    }
    
    func request(for permission: Permission) -> AnyPublisher<Permission.Status,Never> {
        currentPermissionStatus(for: permission)
            .flatMap { [weak self] result -> AnyPublisher<Permission.Status,Never> in
                guard let self = self, result == .notDetermined else {
                    return Just(result).eraseToAnyPublisher()
                }
                return self.requestPublisher(for: permission).eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .map { [weak self] newValue in
                let keyPath = AppState.permissionKeyPath(for: permission)
                self?.appState[keyPath] = newValue
                return newValue
            }.eraseToAnyPublisher()
    }
}

// MARK: - Helpers
extension UserPermissionsInteractor {
    private func requestPublisher(for permission: Permission) -> AnyPublisher<Permission.Status, Never> {
        switch permission {
        case .cameraAccess:
            return requestCameraAccessPermission()
        case .photoLibraryAccess:
            return requestPhotoLibraryPermissionStatus()
        }
    }
    
    private func currentPermissionStatus(for permission: Permission) -> AnyPublisher<Permission.Status, Never> {
        switch permission {
        case .cameraAccess:
            return getCameraAccessPermissionStatus()
        case .photoLibraryAccess:
            return getPhotoLibraryPermisssionStatus()
        }
    }
}

// MARK: - Camera access
extension UserPermissionsInteractor {
    func getCameraAccessPermissionStatus(onResolve completion: @escaping (Permission.Status) -> Void) {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        completion(Permission.Status(from: cameraAuthorizationStatus))
    }
    
    func getCameraAccessPermissionStatus() -> AnyPublisher<Permission.Status, Never> {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        return Just(Permission.Status(from: cameraAuthorizationStatus)).eraseToAnyPublisher()
    }
    
    func requestCameraAccessPermission() -> AnyPublisher<Permission.Status, Never> {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        guard currentStatus == .notDetermined else {
            return Just(Permission.Status(from: currentStatus)).eraseToAnyPublisher()
        }
        return Future<Permission.Status, Never> { promise in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                let newStatus = AVCaptureDevice.authorizationStatus(for: .video)
                return promise(.success(Permission.Status(from: newStatus)))
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - Photo library access
extension UserPermissionsInteractor {
    func getPhotoLibraryPermisssionStatus(onResolve completion: @escaping (Permission.Status) -> Void) {
        let photoLibraryAccessStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        completion(Permission.Status(from: photoLibraryAccessStatus))
    }
    
    func getPhotoLibraryPermisssionStatus() -> AnyPublisher<Permission.Status, Never> {
        let photoLibraryAccessStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        return Just(Permission.Status(from: photoLibraryAccessStatus)).eraseToAnyPublisher()
    }
    
    func requestPhotoLibraryPermissionStatus() -> AnyPublisher<Permission.Status,Never> {
        Future<Permission.Status,Never> { promise in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                return promise(.success(Permission.Status(from: newStatus)))
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - Stub
class StubUserPermissionsLogic: UserPermissionsLogic {
    func resolveStatus(for permission: Permission) -> AnyPublisher<Permission.Status,Never> {
        Empty().eraseToAnyPublisher()
    }
    
    func request(permission: Permission) { }
    
    func request(for permission: Permission) -> AnyPublisher<Permission.Status,Never> {
        Empty().eraseToAnyPublisher()
    }
}
