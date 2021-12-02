//
//  AppEnviroment.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Foundation

struct AppEnviroment {
    let container: DependencyContainer
}

extension AppEnviroment {
    static func bootstrap() -> AppEnviroment {
        let appState = Store<AppState>(AppState())
        
        let repositories = setupRepositories(appState: appState)
        let interactors = setupInteractors(appState: appState, repositiories: repositories)
        
        let depencencyContainer = DependencyContainer(appState: appState, interactors: interactors)
        
        return AppEnviroment(container: depencencyContainer)
    }
    
    private static func setupInteractors(appState: Store<AppState>, repositiories: DependencyContainer.RepositoryContainer) -> DependencyContainer.InteractorContainer {
        let permissionInteractor = UserPermissionsInteractor(appState: appState)
        let imageProcessingInteractor = ImageProcessingInteractor()
        let detectorInteractor = DetectorInteractor(appState: appState, repository: repositiories.detectorDataRepository)
        let systemEventsInteractor = SystemEventsInteractor(appState: appState)
        let userSettingsInteractor = UserSettingsInteractor(appState: appState)
        let purchaseInteractor = PurchaseInteractor(appState: appState)
        let detectorRendererInteractor = DetectorRendererInteractor(appState: appState)
        let userInterfaceInteractor = UserInterfaceInteractor()
        
        #if PREVIEW
        let cameraInteractor = StubCameraServiceLogic()
        #else
        let cameraInteractor = CameraServiceProvider(appState: appState)
        #endif
        
        return DependencyContainer.InteractorContainer(
            permissionInteractor: permissionInteractor,
            cameraInteractor: cameraInteractor,
            imageProcessingInteractor: imageProcessingInteractor,
            detectorInteractor: detectorInteractor,
            systemEventsInteractor: systemEventsInteractor,
            userSettingsInteractor: userSettingsInteractor,
            purchaseInteractor: purchaseInteractor,
            detectorRendererInteractor: detectorRendererInteractor,
            userInterfaceInteractor: userInterfaceInteractor
        )
    }
    
    private static func setupRepositories(appState: Store<AppState>) -> DependencyContainer.RepositoryContainer {
        let plistDataRepository = PlistDataRepository(appState: appState)
        
        return DependencyContainer.RepositoryContainer(detectorDataRepository: plistDataRepository)
    }
}
