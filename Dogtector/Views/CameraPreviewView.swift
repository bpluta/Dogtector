//
//  CameraPreviewView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import AVFoundation

class CameraPreviewView: PreviewView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer? {
        layer as? AVCaptureVideoPreviewLayer
    }
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
}
