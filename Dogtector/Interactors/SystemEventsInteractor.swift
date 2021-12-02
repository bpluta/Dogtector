//
//  SystemEventsInteractor.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import StoreKit
import Combine

protocol SystemEventsLogic {
    func getApplicationInfo() -> ApplicationInfo?
    func copyDebugData() -> AnyPublisher<Void, SystemEventsError>
    func openShareApp() -> AnyPublisher<Void, SystemEventsError>
    func openAppSettings() -> AnyPublisher<Void, SystemEventsError>
    func openShareImageSheet(image: UIImage) -> AnyPublisher<Void, SystemEventsError>
    func openReviewPrompt() -> AnyPublisher<Void, SystemEventsError>
}

class SystemEventsInteractor: SystemEventsLogic {
    private var appState: Store<AppState>
    private var cancelBag = CancelBag()
    
    var lowBatteryModePublisher: AnyPublisher<Bool,Never> { lowBatteryModeSubject.eraseToAnyPublisher() }
    private var lowBatteryModeSubject = PassthroughSubject<Bool,Never>()
    
    init(appState: Store<AppState>) {
        self.appState = appState
        setupLowBatteryStateUpdater()
        setupAppBecomeActiveUpdater()
        setupDeviceOrientationUpdater()
        setupAppDidEnterBackgroundUpdater()
    }
    
    // MARK: - Interface implementations
    func openReviewPrompt() -> AnyPublisher<Void, SystemEventsError> {
        Future { promise in
            guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                return promise(.failure(.openError))
            }
            DispatchQueue.main.async {
                SKStoreReviewController.requestReview(in: scene)
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }
    
    func openShareApp() -> AnyPublisher<Void, SystemEventsError> {
        Future { promise in
            guard let sourceViewController = UIApplication.shared.windows.first?.rootViewController else {
                return promise(.failure(.openError))
            }
            
            let activityItemMetadata = LinkMetadataManager()
            let activityViewController = UIActivityViewController(
                activityItems: [activityItemMetadata],
                applicationActivities: nil
            )
            if let popoverController = activityViewController.popoverPresentationController {
                let sourceRect = CGRect(
                    x: sourceViewController.view.bounds.midX,
                    y: sourceViewController.view.bounds.midY,
                    width: .zero,
                    height: .zero
                )
                popoverController.sourceView = sourceViewController.view
                popoverController.permittedArrowDirections = []
                popoverController.sourceRect = sourceRect
            }
            sourceViewController.present(activityViewController, animated: true) {
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }
    
    func openShareImageSheet(image: UIImage) -> AnyPublisher<Void, SystemEventsError> {
        Future { promise in
            let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true) {
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }
    
    func openAppSettings() -> AnyPublisher<Void, SystemEventsError> {
        Future { promise in
            guard
                let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                UIApplication.shared.canOpenURL(settingsUrl)
            else { return promise(.failure(.openError)) }
            
            UIApplication.shared.open(settingsUrl) { success in
                guard success else {
                    return promise(.failure(.openError))
                }
                return promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }
    
    func copyDebugData() -> AnyPublisher<Void, SystemEventsError> {
        Just(applicationData)
            .encode(encoder: JSONEncoder())
            .map { data in
                String(data: data, encoding: .utf8)
            }.unwrap(orThrow: SystemEventsError.encodingError)
            .mapError { error in
                (error as? SystemEventsError) ?? .encodingError
            }.flatMap { [weak self] in
                self?.copy(string: $0) ?? Fail(error: .encodingError).eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
    
    func getApplicationInfo() -> ApplicationInfo? {
        applicationData
    }
    
    func getDeviceInfo() -> String? {
        let encoder = JSONEncoder()
        guard
            let jsonData = try? encoder.encode(applicationData),
            let jsonString = String(data: jsonData, encoding: .utf8)
        else { return nil }
        return jsonString
    }
}

// MARK: - Helpers
extension SystemEventsInteractor {
    private func setupAppBecomeActiveUpdater() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.appState[\.system.isActive] = true
            }).store(in: cancelBag)
    }
    
    private func setupAppDidEnterBackgroundUpdater() {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.appState[\.system.isActive] = false
            }).store(in: cancelBag)
    }
    
    private func setupLowBatteryStateUpdater() {
        appState[\.system.isLowBatteryModeEnabled] = ProcessInfo.processInfo.isLowPowerModeEnabled
        NotificationCenter.default.publisher(for: Notification.Name.NSProcessInfoPowerStateDidChange)
            .receive(on: DispatchQueue.main)
            .map { _ in ProcessInfo.processInfo.isLowPowerModeEnabled }
            .sink(receiveValue: { [weak self] newValue in
                self?.appState[\.system.isLowBatteryModeEnabled] = newValue
            }).store(in: cancelBag)
    }
    
    private func setupDeviceOrientationUpdater() {
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .map { _ in
               UIDevice.current.orientation
            }.sink(receiveValue: { [weak self] newValue in
                self?.appState[\.system.deviceOrientation] = newValue
            }).store(in: cancelBag)
    }
    
    private func copy(string: String) -> AnyPublisher<Void, SystemEventsError> {
        Future { promise in
            let pasteboard = UIPasteboard.general
            pasteboard.string = string
            return promise(.success(()))
        }.eraseToAnyPublisher()
    }
    
    private var applicationData: ApplicationInfo {
        ApplicationInfo(
            appLanguage: applicationLanguage,
            systemLanguage: systemLanguage,
            systemVersion: systemVersion,
            deviceResolution: resolution,
            appVersion: appVersion,
            deviceModel: deviceModel,
            objectDecoderType: objectDecoderType
        )
    }
    
    private var applicationLanguage: String? {
        Locale.preferredLanguages.first
    }
    
    private var systemLanguage: String? {
        NSLocale.current.languageCode
    }
    
    private var systemVersion: String {
        UIDevice.current.systemVersion
    }
    
    private var appVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    private var resolution: String {
        let bounds = UIScreen.main.bounds
        let width = Int(bounds.width)
        let height = Int(bounds.height)
        return "\(width) x \(height)"
    }
    
    private var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        return modelCode ?? UIDevice.current.model
    }
    
    private var objectDecoderType: String? {
        appState[\.detectorData.decoderType]?.rawValue
    }
}

// MARK: - Stub
class StubSystemEventsLogic: SystemEventsLogic {
    func getApplicationInfo() -> ApplicationInfo? { nil }
    
    func copyDebugData() -> AnyPublisher<Void,SystemEventsError> { Empty().eraseToAnyPublisher() }
    
    func openShareImageSheet(image: UIImage) -> AnyPublisher<Void, SystemEventsError> { Empty().eraseToAnyPublisher() }
    
    func openShareApp() -> AnyPublisher<Void, SystemEventsError> { Empty().eraseToAnyPublisher() }
    
    func openAppSettings() -> AnyPublisher<Void, SystemEventsError> { Empty().eraseToAnyPublisher() }
    
    func openReviewPrompt() -> AnyPublisher<Void, SystemEventsError> { Empty().eraseToAnyPublisher() }
}
