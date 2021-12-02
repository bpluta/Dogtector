//
//  PurchaseModels.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import StoreKit

struct PurchaseRequestItem {
    let title: String
    let description: String
    let productId: String
    
    init(from tip: TipPurchase) {
        self.title = tip.title
        self.description = tip.description
        self.productId = tip.productId
    }
}

struct PurchaseItem: Identifiable {
    let title: String
    let description: String
    let price: String
    let product: SKProduct
    
    let id = UUID()
    
    init?(from product: SKProduct) {
        guard let price = product.formattedPrice else { return nil }
        self.title = product.localizedTitle
        self.description = product.localizedDescription
        self.price = price
        self.product = product
    }
    
    init?(title: String, description: String, product: SKProduct) {
        guard let price = product.formattedPrice else { return nil }
        self.title = title
        self.description = description
        self.price = price
        self.product = product
    }
}

enum TipPurchase: CaseIterable {
    case niceGesture
    case greatHelp
    case amazingSupport
    
    var title: String {
        switch self {
        case .niceGesture:
            return "TipJarNiceGestureTipTitle".localized
        case .greatHelp:
            return "TipJarGreatHelpTipTitle".localized
        case .amazingSupport:
            return "TipJarAmazingSupportTipTitle".localized
        }
    }
    
    var description: String {
        switch self {
        case .niceGesture:
            return "TipJarNiceGestureTipDescription".localized
        case .greatHelp:
            return "TipJarGreatHelpTipDescription".localized
        case .amazingSupport:
            return "TipJarAmazingSupportTipDescription".localized
        }
    }
    
    var productId: String {
        switch self {
        case .niceGesture:
            return "dogtector_tip_nice_gesture"
        case .greatHelp:
            return "dogtector_tip_great_help"
        case .amazingSupport:
            return "dogtector_tip_amazing_support"
        }
    }
}

enum PurchaseError: Error {
    case noProductIDsFound
    case noProductsFound
    case paymentWasCancelled
    case productRequestFailed
    case noPurchasesToRestore
    case notAllowedToMakePurchases
    case otherTransactionError
    
    var description: String {
            switch self {
            case .noProductIDsFound:
                return "InAppPurchaseNoProductIdFoundError".localized
            case .noProductsFound:
                return "InAppPurchaseNoProductsFoundError".localized
            case .productRequestFailed:
                return "InAppPurchaseProductRequestFailedError".localized
            case .paymentWasCancelled:
                return "InAppPurchasePaymentWasCancelledError".localized
            case .noPurchasesToRestore:
                return "InAppPurchaseNoPurchasesToRestoreError".localized
            case .notAllowedToMakePurchases:
                return "InAppPurchaseNotAllowedtoMakePurchasesError".localized
            case .otherTransactionError:
                return "InAppPurchaseOtherTransactionError".localized
            }
        }
    
    init(from error: SKError) {
        let isPaymentCancelled = error.code == .paymentCancelled
        if isPaymentCancelled {
            self = .paymentWasCancelled
        } else {
            self = .otherTransactionError
        }
    }
}
