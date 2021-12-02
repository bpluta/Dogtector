//
//  UIImageExtension.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import UIKit

extension UIImage {
    public var pixelBuffer: CVPixelBuffer? {
        var maybePixelBuffer: CVPixelBuffer?
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attributes as CFDictionary,
            &maybePixelBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else { return nil }
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

        guard let content = CGContext(
                data: pixelData,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }

        content.translateBy(x: 0, y: CGFloat(size.height))
        content.scaleBy(x: 1, y: -1)

        UIGraphicsPushContext(content)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }
    
    var sharedSheetPreviewIcon: UIImage {
        let replaceTransparencyWithColor = UIColor.black
        let minimumSize: CGFloat = 40.0

        let format = UIGraphicsImageRendererFormat.init()
        format.opaque = true
        format.scale = scale

        let imageWidth = size.width
        let imageHeight = size.height
        let imageSmallestDimension = max(imageWidth, imageHeight)
        let deviceScale = UIScreen.main.scale
        let resizeFactor = minimumSize * deviceScale  / (imageSmallestDimension * scale)

        var size = size
        if resizeFactor > 1.0 {
            size = CGSize(
                width: imageWidth * resizeFactor,
                height: imageHeight * resizeFactor
            )
        }
        let renderedImage = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let imageRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            let size = context.format.bounds.size
            
            replaceTransparencyWithColor.setFill()
            context.fill(imageRect)
        
            self.draw(in: CGRect(origin: .zero, size: size))
        }
        return renderedImage
    }
}
