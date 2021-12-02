//
//  TipJarView.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import Combine

// MARK: - Models
extension TipJarView {
    class ViewModel: ObservableObject {
        @Published var purchaseItems: [PurchaseItem] = []
        @Published var doNotShowAgain: Bool = false
        @Published var hasPurchaseDataBeenLoaded: Bool = false
        @Published var downloadDidFail: Bool = false
        @Published var isLoaderPresented: Bool = false
        
        var isConfigured: Bool = false
    }
}

// MARK: - View
struct TipJarView: View {
    @Environment(\.notificationPublisher) private var notificationPublisher: NotificationSubject
    @Environment(\.injected) private var injected: DependencyContainer
    @StateObject private var viewModel = ViewModel()
    
    var cancelBag = CancelBag()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Icon()
                Group {
                    Title()
                    Description()
                }.padding(.horizontal, isLargerDevice ? 10 : 0)
                TipOptions()
                    .padding(.top, 20)
            }.padding(.vertical, isLargerDevice ? 40 : 20)
            .padding(.horizontal, 20)
        }
        .navigationWithCloseButton()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: getProducts)
        .onAppear(perform: setupView)
        .activityIndicator(isPresented: $viewModel.isLoaderPresented)
    }
    
    @ViewBuilder
    private func Title() -> some View {
        Text("TipJarPromptTitle".localized)
            .font(.system(size: 30, weight: .bold))
            .multilineTextAlignment(.center)
            .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func Description() -> some View {
        Text("TipJarPromptDescription".localized)
            .font(.system(size: 15))
            .multilineTextAlignment(.center)
            .foregroundColor(Theme.Color.gray.color)
    }
    
    @ViewBuilder
    private func TipOptions() -> some View {
        if viewModel.hasPurchaseDataBeenLoaded {
            if viewModel.downloadDidFail {
                FetchError()
            } else {
                TipsContent()
            }
        } else {
            TipsPlaceholder()
        }
    }
    
    @ViewBuilder
    private func TipsContent() -> some View {
        VStack(alignment: .center, spacing: 15) {
            ForEach(viewModel.purchaseItems) { product in
                TipItem(product: product)
            }
        }
    }
    
    @ViewBuilder
    private func TipsPlaceholder() -> some View {
        VStack(alignment: .center, spacing: 15) {
            ForEach(1...3, id: \.self) { _ in
                TipItemCell()
            }
        }
    }
    
    @ViewBuilder
    private func TipItem(product: PurchaseItem) -> some View {
        Button(action: { purchase(item: product) }) {
            TipItemCell(
                title: product.title,
                description: product.description,
                price: product.price
            )
        }.buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func FetchError() -> some View {
        VStack(alignment: .center, spacing: 15) {
            Theme.Image.xmark
                .resizable()
                .scaledToFit()
                .font(Font.title.weight(.semibold))
                .foregroundColor(Theme.Color.red.color)
                .frame(width: 50)
                .fixedSize(horizontal: false, vertical: true)
            Text("TipJarFetchErrorDescription".localized)
                .multilineTextAlignment(.center)
                .font(.system(size: 16))
                .foregroundColor(Theme.Color.gray.color)
                .padding(.horizontal, 20)
                .fixedSize(horizontal: false, vertical: true)
        }.padding(20)
        .frame(maxWidth: .infinity)
        .background(Theme.Color.adaptiveLighterGray.color.cornerRadius(20))
    }
    
    @ViewBuilder
    private func Icon() -> some View {
        ZStack {
            BackgroundGradient().mask(
                RoundedRectangle(cornerRadius: isLargerDevice ? 30 : 20)
                    .aspectRatio(1.0, contentMode: .fit)
            )
            Theme.Image.heart
                .resizable()
                .scaledToFit()
                .foregroundColor(Theme.Color.white.color)
                .padding(isLargerDevice ? 30 : 20)
        }.aspectRatio(1.0, contentMode: .fit)
        .frame(width: isLargerDevice ? 140 : 100)
    }
    
    private func BackgroundGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Theme.Color.red.color, Theme.Color.pink.color]),
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }
}

// MARK: - Setup
extension TipJarView {
    private func setupView() {
        guard !viewModel.isConfigured else { return }
        setupPurchaseDataLoadStateUpdater()
        viewModel.isConfigured = true
    }
    
    private func setupPurchaseDataLoadStateUpdater() {
        viewModel.$purchaseItems
            .dropFirst()
            .sink(receiveValue: { _ in
                viewModel.hasPurchaseDataBeenLoaded = true
            }).store(in: cancelBag)
    }
}

// MARK: - Helpers
extension TipJarView {
    private func getProducts() {
        Just(TipPurchase.allCases)
            .map { tips in
                tips.map { PurchaseRequestItem(from: $0) }
            }.flatMap { requests in
                injected.interactors.purchaseInteractor.getProducts(productRequests: requests)
            }.receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                viewModel.hasPurchaseDataBeenLoaded = true
                if case .failure(let error) = completion {
                    viewModel.downloadDidFail = true
                    let notificationModel = NotificationModel(
                        type: .failure,
                        message: error.description,
                        color: Theme.Color.listBackground.color
                    )
                    showNotification(notificationModel)
                }
            }, receiveValue: { products in
                viewModel.purchaseItems = products
            }).store(in: cancelBag)
    }
    
    private func purchase(item: PurchaseItem) {
        viewModel.isLoaderPresented = true
        injected.interactors.purchaseInteractor.checkIfCanMakePayments()
            .flatMap {
                injected.interactors.purchaseInteractor.purchase(product: item.product)
            }.receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                viewModel.isLoaderPresented = false
                if case .failure(let error) = completion {
                    let notificationModel = NotificationModel(
                        type: .failure,
                        message: error.description,
                        color: Theme.Color.listBackground.color
                    )
                    showNotification(notificationModel)
                }
            }, receiveValue: {
                viewModel.doNotShowAgain = true
                let notificationModel = NotificationModel(
                    type: .success,
                    message: "TipJarSuccessMessage".localized,
                    color: Theme.Color.listBackground.color
                )
                showNotification(notificationModel)
            }).store(in: cancelBag)
    }
    
    private func showNotification(_ notification: NotificationModel) {
        injected.interactors.userInterfaceInteractor.showNotification(notification, with: notificationPublisher)
    }
}

#if DEBUG
struct TipJarPreview: PreviewProvider {
    static var previews: some View {
        TipJarView()
    }
}
#endif
