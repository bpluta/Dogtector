//
//  NavigationConfigurator.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct NavigationConfigurator: UIViewControllerRepresentable {
    var configure: (UINavigationController) -> Void = { _ in }

    func makeUIViewController(context: UIViewControllerRepresentableContext<NavigationConfigurator>) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<NavigationConfigurator>) {
        if let navigationController = uiViewController.navigationController {
            self.configure(navigationController)
        }
    }
}
