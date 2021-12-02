//
//  NotificationBox.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import Combine

typealias NotificationModel = NotificationBox.Model
typealias NotificationSubject = PassthroughSubject<NotificationModel,Never>
typealias NotificationPublisher = AnyPublisher<NotificationModel,Never>

struct NotificationBox: View {
    struct Model: Equatable {
        let type: NotificationType
        let message: String
        let color: Color
        
        init(type: NotificationType, message: String, color: Color = Theme.Color.listBackgroundInverted.color) {
            self.type = type
            self.message = message
            self.color = color
        }
    }
    
    let type: NotificationType
    let color: Color
    let content: String
    
    var body: some View {
            HStack(alignment: .center, spacing: 5) {
                type.image
                    .frame(width: 25)
                Text(content)
                    .font(.callout)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 5)
            }
            .padding(15)
            .background(color.clipShape(Capsule()))
    }
}

// MARK: - View Modifier
extension NotificationBox {
    struct NotificationModifier: ViewModifier {
        class ViewModel: ObservableObject {
            @Published var notification: NotificationModel?
            
            var notificationPublisher: NotificationPublisher
            var notificationCancellable: AnyCancellable?
            var cancellables: Set<AnyCancellable> = []
            
            init(notificationPublisher: NotificationPublisher) {
                self.notificationPublisher = notificationPublisher
            }
        }
        
        @ObservedObject private var viewModel: ViewModel
        
        init(notificationPublisher: NotificationPublisher) {
            viewModel = ViewModel(notificationPublisher: notificationPublisher)
            setupNotificationPipeline()
        }
        
        func body(content: Content) -> some View {
            ZStack {
                content
                VStack {
                    if let notificationModel = viewModel.notification {
                        Notification(model: notificationModel)
                    }
                    Spacer()
                }
            }
        }
        
        @ViewBuilder
        private func Notification(model: NotificationModel) -> some View {
            NotificationBox(type: model.type, color: model.color, content: model.message)
                .padding(.top, 20)
                .frame(maxWidth: 300)
                .transition(.move(edge: .top).combined(with: .opacity))
                .gesture(onSwipeUpGesture(hideNotification))
        }
        
        private func setupNotificationPipeline() {
            viewModel.notificationPublisher.sink { notification in
                show(notification: notification)
            }.store(in: &viewModel.cancellables)
        }
        
        private func onSwipeUpGesture(_ action: (() -> Void)) -> some Gesture {
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onEnded({ value in
                    guard value.translation.height < 0 else { return }
                    hideNotification()
                })
        }
        
        private func show(notification: NotificationModel) {
            viewModel.notificationCancellable?.cancel()
            viewModel.notificationCancellable = nil
            
            withAnimation { viewModel.notification = notification }
            viewModel.notificationCancellable = Just(())
                .delay(for: .seconds(notification.type.timeToLive), scheduler: DispatchQueue.main)
                .sink { _ in
                    withAnimation { viewModel.notification = nil }
                }
        }
        
        private func hideNotification() {
            viewModel.notificationCancellable?.cancel()
            viewModel.notificationCancellable = nil
            withAnimation { viewModel.notification = nil }
        }
    }
}

extension View {
    func showNotification(_ publisher: NotificationSubject) -> some View {
        self.modifier(NotificationBox.NotificationModifier(notificationPublisher: publisher.eraseToAnyPublisher()))
            .environment(\.notificationPublisher, publisher)
    }
}

// MARK: - Notification Types
extension NotificationBox {
    enum NotificationType {
        case success
        case warning
        case failure
        case info
        case donation
        
        var image: some View {
            contentImage
                .resizable()
                .scaledToFit()
                .foregroundColor(imageColor)
        }
        
        var timeToLive: Double {
            switch self {
            case .success, .failure:
                return 2.0
            case .warning, .info, .donation:
                return 3.5
            }
        }
        
        private var contentImage: Image {
            switch self {
            case .success:
                return Theme.Image.success
            case .warning:
                return Theme.Image.warning
            case .failure:
                return Theme.Image.failure
            case .info:
                return Theme.Image.info
            case .donation:
                return Theme.Image.filledHeart
            }
        }
        
        private var imageColor: Color {
            switch self {
            case .success:
                return Theme.Color.green.color
            case .warning:
                return Theme.Color.orange.color
            case .failure:
                return Theme.Color.red.color
            case .info:
                return Theme.Color.blue.color
            case .donation:
                return Theme.Color.red.color
            }
        }
    }
}

#if DEBUG
struct NotificationBoxPreview: PreviewProvider {
    static var previews: some View {
        ZStack {
            Theme.Color.black.color.ignoresSafeArea(edges: .all)
            VStack(alignment: .center, spacing: 20) {
                NotificationBox(
                    type: .success,
                    color: Theme.Color.listBackgroundInverted.color,
                    content: "ImageProcessingSaveError".localized)
                    .frame(maxWidth: 300)
                NotificationBox(
                    type: .warning,
                    color: Theme.Color.listBackgroundInverted.color,
                    content: "ImageProcessingNotAuthorizedError".localized)
                    .frame(maxWidth: 300)
                NotificationBox(
                    type: .failure,
                    color: Theme.Color.listBackgroundInverted.color,
                    content: "CameraTakeImageError".localized)
                    .frame(maxWidth: 300)
                NotificationBox(
                    type: .info,
                    color: Theme.Color.listBackgroundInverted.color,
                    content: "CameraNotAuthorizedError".localized)
                    .frame(maxWidth: 300)
                Spacer()
            }
        }
    }
}
#endif
