//
//  CGSizeExtension.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

extension CGSize {
    func normalize(by size: CGSize) -> CGSize {
        let primaryRatio = width / height
        let boundRatio = size.width / size.height
        
        let normalizedRatio = primaryRatio / boundRatio
        
        if primaryRatio > boundRatio {
            return CGSize(width: size.width, height: size.height / normalizedRatio)
        } else {
            return CGSize(width: size.width / normalizedRatio, height: size.height)
        }
    }
    
    static func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}
