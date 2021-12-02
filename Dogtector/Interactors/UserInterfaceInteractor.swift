//
//  UserInterfaceInteractor.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Foundation
import Combine

protocol UserInterfaceInteractionLogic {
    func showNotification(_ notification: NotificationModel, with publisher: NotificationSubject)
}

// MARK: - Interface implementations
class UserInterfaceInteractor: UserInterfaceInteractionLogic {
    func showNotification(_ notification: NotificationModel, with publisher: NotificationSubject) {
        DispatchQueue.main.async {
            publisher.send(notification)
        }
    }
}

// MARK: - Stub
class StubUserInterfaceInteractor: UserInterfaceInteractionLogic {
    func showNotification(_ notification: NotificationModel, with publisher: NotificationSubject) { }
}
