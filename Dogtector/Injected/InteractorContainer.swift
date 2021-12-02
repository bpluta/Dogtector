//
//  InteractorContainer.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Foundation

extension DependencyContainer {
    struct InteractorContainer {
        let permissionInteractor: UserPermissionsLogic
        let cameraInteractor: CameraServiceLogic
        let imageProcessingInteractor: ImageProcessingLogic
        let detectorInteractor: DetectorLogic
        let systemEventsInteractor: SystemEventsLogic
        let userSettingsInteractor: UserSettingsLogic
        let purchaseInteractor: PurchaseLogic
        let detectorRendererInteractor: DetectorRendererLogic
        let userInterfaceInteractor: UserInterfaceInteractionLogic
        
        static var stub: Self {
            .init(permissionInteractor: StubUserPermissionsLogic(),
                  cameraInteractor: StubCameraServiceLogic(),
                  imageProcessingInteractor: StubImageProcessingLogic(),
                  detectorInteractor: StubDetectorLogic(),
                  systemEventsInteractor: StubSystemEventsLogic(),
                  userSettingsInteractor: StubUserSettingsLogic(),
                  purchaseInteractor: StubPurchaseLogic(),
                  detectorRendererInteractor: StubDetectorRendererInteractor(),
                  userInterfaceInteractor: StubUserInterfaceInteractor()
            )
        }
    }
}
