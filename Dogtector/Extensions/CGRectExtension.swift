//
//  CGRectExtension.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

extension CGRect {
    init(size: CGSize) {
        self = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    }
}
