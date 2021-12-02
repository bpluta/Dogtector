//
//  DogtectorApp.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

@main
struct DogtectorApp: App {
    let enviroment: AppEnviroment = AppEnviroment.bootstrap()
    
    init() {
       setup()
    }
    
    var body: some Scene {
        WindowGroup {
            Theme.Color.black.color
                .onAppear(perform: switchHostingController)
        }
    }
    
    private func setup() {
        enviroment.container.interactors.detectorInteractor.loadDetectionData()
    }
    
    private func switchHostingController() {
        UIApplication.shared.switchHostingController(container: enviroment.container)
    }
}

class HostingController: UIHostingController<ContentView> {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        UIApplication.statusBarStyle
    }
    
    override var childForStatusBarStyle: UIViewController? { nil }
}

extension UIApplication {
    static var hostingController: HostingController?
    static var statusBarStyle: UIStatusBarStyle = .default
    
    static func setStatusBarStyle(_ style: UIStatusBarStyle) {
        statusBarStyle = style
        hostingController?.setNeedsStatusBarAppearanceUpdate()
    }
    
    func switchHostingController(container: DependencyContainer) {
        let hostingController = HostingController(rootView: ContentView(container: container))
        windows.first?.rootViewController = hostingController
        windows.first?.makeKeyAndVisible()
    }
}
