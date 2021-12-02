//
//  SKProductExtension.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import StoreKit

extension SKProduct {
    var formattedPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price)
    }
}
