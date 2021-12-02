//
//  FloatExtension.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Foundation

extension Float {
    var roundedPercentageString: String {
        "\(String(format: "%.0f", self * 100))%"
    }
    
    var percentageString: String {
        "\(String(format: "%.1f", self * 100))%"
    }
    
    var detailedPercentageString: String {
        "\(String(format: "%.2f", self * 100))%"
    }
}
