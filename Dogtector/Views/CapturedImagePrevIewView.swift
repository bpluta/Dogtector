//
//  CapturedImagePreviewView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import UIKit

class CapturedImagePreviewView: PreviewView {
    private let imageView = UIImageView()
    private let scrollableImageContainer = UIView()
    
    override func setupView() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        
        addSubview(imageView)
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        imageView.layer.addSublayer(detectionLayer)
    }
    
    func load(image: UIImage?) {
        imageView.image = image
    }
}
