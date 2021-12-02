//
//  SafariView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.preferredControlTintColor = Theme.Color.primaryContrastive
        return safariViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}
