//
//  UIColorExtension.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import UniformTypeIdentifiers

extension UIColor {
    convenience init?(hexString: String?) {
        guard let hexString = hexString, hexString ~= "^#[0-9A-Fa-f]{1,6}$" else { return nil }
        let hex = hexString.replacingOccurrences(of: "#", with: "").lowercased()
        
        guard let rgbValue = Int(hex, radix: 16) else { return nil }
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    var hexString: String? {
        guard let components = cgColor.components, components.count >= 3 else { return nil }
        
        let r = normalizeToColorByte(value: components[0])
        let g = normalizeToColorByte(value: components[1])
        let b = normalizeToColorByte(value: components[2])
        
        return String(format: "#%02lX%02lX%02lX", r, g, b)
    }
    
    var color: Color {
        Color(self)
    }
}

// MARK: - Helpers
extension UIColor {
    private func normalizeToColorByte(value: CGFloat) -> UInt8 {
        UInt8(max(min(round(Float(value) * 0xFF), 0xFF), 0))
    }
}
