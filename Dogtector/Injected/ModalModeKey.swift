//
//  ModalModeKey.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI

struct ModalModeKey: EnvironmentKey {
    static let defaultValue = Binding<Bool>.constant(false)
}

extension EnvironmentValues {
    var modalMode: Binding<Bool> {
        get {
            self[ModalModeKey.self]
        }
        set {
            self[ModalModeKey.self] = newValue
        }
    }
}
