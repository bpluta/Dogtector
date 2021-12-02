//
//  ViewExtension.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

extension View {
    var isLargerDevice: Bool {
        UIScreen.main.bounds.size.width >= CGFloat(375)
    }
}
