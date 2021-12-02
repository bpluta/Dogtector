//
//  NotificationPublisherKey.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct NotificationPublisherKey: EnvironmentKey {
    static let defaultValue = NotificationSubject()
}

extension EnvironmentValues {
    var notificationPublisher: NotificationSubject {
        get {
            self[NotificationPublisherKey.self]
        }
        set {
            self[NotificationPublisherKey.self] = newValue
        }
    }
}

