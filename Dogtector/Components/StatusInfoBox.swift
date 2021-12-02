//
//  StatusInfoBox.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import Combine

typealias StatusModel = StatusInfoBox.Model
typealias StatusSubject = PassthroughSubject<StatusModel,Never>
typealias StatusPublisher = AnyPublisher<StatusModel,Never>

struct StatusInfoBox: View {
    struct Model: Equatable {
        let message: String
        let timeToLive: Double = 2
    }
    
    let message: String
    
    var body: some View {
        Text(message.uppercased())
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundColor(Color.black)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(Color.yellow.opacity(0.8))
            .cornerRadius(5)
    }
}

// MARK: - View Modifier
extension StatusInfoBox {
    class StatusBag: ObservableObject {
        @Published fileprivate var status: StatusModel?
        
        fileprivate var statusCancellable: AnyCancellable?
        fileprivate var cancellables: Set<AnyCancellable> = []
    }
    
    struct StatusModifier: ViewModifier {
        @ObservedObject private var statusBag: StatusBag
        
        var statusPublisher: StatusPublisher
        
        init(statusPublisher: StatusPublisher, statusBag: StatusBag) {
            self.statusPublisher = statusPublisher
            self.statusBag = statusBag
            setupNotificationPipeline()
        }
        
        func body(content: Content) -> some View {
            ZStack {
                content
                VStack {
                    if let statusModel = statusBag.status {
                        StatusInfoBox(message: statusModel.message)
                            .padding(.top, 20)
                            .frame(maxWidth: 200)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    Spacer()
                }
            }
        }
        
        private func setupNotificationPipeline() {
            statusPublisher.sink { status in
                show(status: status)
            }.store(in: &statusBag.cancellables)
        }
        
        private func show(status: StatusModel) {
            statusBag.statusCancellable?.cancel()
            statusBag.statusCancellable = nil
            
            withAnimation { statusBag.status = status }
            statusBag.statusCancellable = Just(())
                .delay(for: .seconds(2), scheduler: DispatchQueue.main)
                .sink { _ in
                    withAnimation { statusBag.status = nil }
                }
        }
        
        private func hideNotification() {
            statusBag.statusCancellable?.cancel()
            statusBag.statusCancellable = nil
            withAnimation { statusBag.status = nil }
        }
    }
}

extension View {
    func showStatus(_ publisher: StatusSubject, statusBag: StatusInfoBox.StatusBag = .init()) -> some View {
        modifier(
            StatusInfoBox.StatusModifier(
                statusPublisher: publisher.eraseToAnyPublisher(),
                statusBag: statusBag
            )
        )
    }
}

#if DEBUG
struct StatusInfoBoxPreview: PreviewProvider {
    static var previews: some View {
        VStack {
            StatusInfoBox(message: "LiveDetectionHasBeenEnabled".localized)
                .frame(maxWidth: 200)
            StatusInfoBox(message: "FlashHasBeenDisabled".localized)
                .frame(maxWidth: 200)
        }.previewLayout(.device)
    }
}
#endif
