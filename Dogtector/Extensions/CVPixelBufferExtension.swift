//
//  CVPixelBufferExtension.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import CoreImage
import AVFoundation

extension CVPixelBuffer {
    func rotate(to orientation: OutputOrientation) -> CVPixelBuffer? {
        guard orientation != .portarait else { return self }
        
        var newPixelBuffer: CVPixelBuffer?
        let newWidth = orientation == .upsideDown ? CVPixelBufferGetWidth(self) : CVPixelBufferGetHeight(self)
        let newHeight = orientation == .upsideDown ? CVPixelBufferGetHeight(self) : CVPixelBufferGetWidth(self)
        
        let error = CVPixelBufferCreate(kCFAllocatorDefault, newWidth, newHeight, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, nil, &newPixelBuffer)
        guard error == kCVReturnSuccess, let buffer = newPixelBuffer else { return nil }
        
        let orientation = CGImagePropertyOrientation(from: orientation)
        let ciImage = CIImage(cvPixelBuffer: self).oriented(orientation)
        let context = getContext()
        context.render(ciImage, to: buffer)
        
        return buffer
    }
    
    private func getContext() -> CIContext {
        guard let metalDevice = AppDefaults.metalDevice else {
            return CIContext(options: nil)
        }
        return CIContext(mtlDevice: metalDevice)
    }
    
    private func copyBuffer() -> CVPixelBuffer? {
        var copyOutput: CVPixelBuffer?
        
        let bufferWidth = CVPixelBufferGetWidth(self)
        let bufferHeight = CVPixelBufferGetHeight(self)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        let bufferFormat = CVPixelBufferGetPixelFormatType(self)
            
        _ = CVPixelBufferCreate(kCFAllocatorDefault, bufferWidth, bufferHeight, bufferFormat, CVBufferGetAttachments(self, CVAttachmentMode.shouldPropagate), &copyOutput)
        
        guard let output = copyOutput else { return nil}
        
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
        CVPixelBufferLockBaseAddress(output, CVPixelBufferLockFlags(rawValue: 0))
        
        let baseAddress = CVPixelBufferGetBaseAddress(self)
        let baseAddressCopy = CVPixelBufferGetBaseAddress(output)
        memcpy(baseAddressCopy, baseAddress, bufferHeight * bytesPerRow)
            
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags.readOnly)
        CVPixelBufferUnlockBaseAddress(output, CVPixelBufferLockFlags(rawValue: 0))
        
        return output
    }
}
