//
//  IdentifiableContainer.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Foundation

struct IdentifiableContainer<T>: Identifiable {
    let id = UUID()
    let content: T
}
