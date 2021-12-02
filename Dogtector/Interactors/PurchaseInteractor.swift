//
//  DonateInteractor.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Combine
import StoreKit

protocol PurchaseLogic {
    func checkIfCanMakePayments() -> AnyPublisher<Void, PurchaseError>
    func getProducts(productRequests: [PurchaseRequestItem]) -> AnyPublisher<[PurchaseItem], PurchaseError>
    func purchase(product: SKProduct) -> AnyPublisher<Void, PurchaseError>
    func restorePurchases() -> AnyPublisher<Void, PurchaseError>
}

class PurchaseInteractor: NSObject, PurchaseLogic {
    private var appState: Store<AppState>
    
    private var cancelBag: CancelBag = CancelBag()
    private var cachedProducts: Set<SKProduct> = []
    
    private var purchaseDelegate = PurchaseManager.shared
    
    init(appState: Store<AppState>) {
        self.appState = appState
        super.init()
    }
    
    // MARK: - Interface implementations
    func checkIfCanMakePayments() -> AnyPublisher<Void, PurchaseError> {
        Future { promise in
            let canMakePayments = SKPaymentQueue.canMakePayments()
            if canMakePayments {
                promise(.success(()))
            } else {
                promise(.failure(.notAllowedToMakePurchases))
            }
        }.eraseToAnyPublisher()
    }
    
    func getProducts(productRequests: [PurchaseRequestItem]) -> AnyPublisher<[PurchaseItem], PurchaseError> {
        Future<[SKProduct], PurchaseError> { [weak self] promise in
            guard let self = self else { return }
            if let cachedProducts = self.getCachedProducts(productRequests: productRequests) {
                return promise(.success(cachedProducts))
            }
            self.purchaseDelegate.productStatusSubject
                .first()
                .sink(receiveValue: { result in
                    switch result {
                    case .success(let products):
                        for product in products {
                            self.cachedProducts.insert(product)
                        }
                        return promise(.success(products))
                    case .failure(let error):
                        return promise(.failure(error))
                    }
                }).store(in: self.cancelBag)
            let productIDs = productRequests.map(\.productId)
            let request = SKProductsRequest(productIdentifiers: Set(productIDs))
            request.delegate = self.purchaseDelegate
            request.start()
        }.map { products in
            productRequests.compactMap { request in
                guard let product = products.first(where: { $0.productIdentifier == request.productId }) else { return nil }
                return PurchaseItem(
                    title: request.title,
                    description: request.description,
                    product: product
                )
            }
        }.eraseToAnyPublisher()
    }
    
    func purchase(product: SKProduct) -> AnyPublisher<Void, PurchaseError> {
        Future { [weak self] promise in
            guard let self = self else { return }
            self.purchaseDelegate.transactionStatusSubject
                .first()
                .sink(receiveValue: { result in
                    switch result {
                    case .success():
                        return promise(.success(()))
                    case .failure(let error):
                        return promise(.failure(error))
                    }
                }).store(in: self.cancelBag)
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }.eraseToAnyPublisher()
    }
    
    func restorePurchases() -> AnyPublisher<Void, PurchaseError> {
        Future { [weak self] promise in
            guard let self = self else { return }
            self.purchaseDelegate.restoredPurchasesSubject
                .first()
                .sink(receiveValue: { result in
                    switch result {
                    case .success:
                        return promise(.success(()))
                    case .failure(let error):
                        return promise(.failure(error))
                    }
                }).store(in: self.cancelBag)
            self.purchaseDelegate.clearRestoredPurchases()
            SKPaymentQueue.default().restoreCompletedTransactions()
        }.eraseToAnyPublisher()
    }
}

// MARK: - Helpers
extension PurchaseInteractor {
    private func getCachedProducts(productRequests: [PurchaseRequestItem]) -> [SKProduct]? {
        let areAllProductsCached = productRequests.allSatisfy { productRequest in
            cachedProducts.contains(where: { $0.productIdentifier == productRequest.productId })
        }
        guard areAllProductsCached else { return nil }
        let filteredCachedProducts = cachedProducts.filter { cachedProduct in
            productRequests.contains(where: { $0.productId == cachedProduct.productIdentifier})
        }
        return Array(filteredCachedProducts)
    }
}

// MARK: - PurchaseManager
extension PurchaseInteractor {
    fileprivate class PurchaseManager: NSObject {
        static let shared = PurchaseManager()
        
        private var restoredPurchasesCount: Int = 0
        
        fileprivate var productStatusSubject = PassthroughSubject<Result<[SKProduct], PurchaseError>, Never>()
        fileprivate var restoredPurchasesSubject = PassthroughSubject<Result<Void, PurchaseError>, Never>()
        fileprivate var transactionStatusSubject = PassthroughSubject<Result<Void, PurchaseError>, Never>()
        
        private override init() {
            super.init()
            SKPaymentQueue.default().add(self)
        }
        
        deinit {
            SKPaymentQueue.default().remove(self)
        }
        
        func clearRestoredPurchases() {
            restoredPurchasesCount = 0
        }
    }
}

// MARK: - SKProductsRequestDelegate
extension PurchaseInteractor.PurchaseManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        guard !products.isEmpty else {
            return productStatusSubject.send(.failure(.noProductsFound))
        }
        productStatusSubject.send(.success(products))
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        productStatusSubject.send(.failure(.productRequestFailed))
    }
}

// MARK: - SKPaymentTransactionObserver
extension PurchaseInteractor.PurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                transactionStatusSubject.send(.success(()))
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                restoredPurchasesCount += 1
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                if let error = transaction.error as? SKError {
                    let purchaseFailureStatus = PurchaseError(from: error)
                    transactionStatusSubject.send(.failure(purchaseFailureStatus))
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .deferred, .purchasing: break
            @unknown default: break
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        guard restoredPurchasesCount > 0 else {
            return restoredPurchasesSubject.send(.failure(.noPurchasesToRestore))
        }
        restoredPurchasesSubject.send(.success(()))
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        guard let error = error as? SKError else { return }
        let restoreFailureStatus = PurchaseError(from: error)
        restoredPurchasesSubject.send(.failure(restoreFailureStatus))
    }
}

// MARK: - Stub
class StubPurchaseLogic: PurchaseLogic {
    func checkIfCanMakePayments() -> AnyPublisher<Void, PurchaseError> {
        Empty().eraseToAnyPublisher()
    }
    
    func getProducts(productRequests: [PurchaseRequestItem]) -> AnyPublisher<[PurchaseItem], PurchaseError> {
        Empty().eraseToAnyPublisher()
    }
    
    func purchase(product: SKProduct) -> AnyPublisher<Void, PurchaseError> {
        Empty().eraseToAnyPublisher()
    }
    
    func restorePurchases() -> AnyPublisher<Void, PurchaseError> {
        Empty().eraseToAnyPublisher()
    }
}
