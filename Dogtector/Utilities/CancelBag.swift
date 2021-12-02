//
//  CancelBag.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Combine

final class CancelBag {
    fileprivate(set) var cancellables: Set<AnyCancellable> = []
    
    func cancel() {
        cancellables.removeAll()
    }
}

extension AnyCancellable {
    func store(in cancelBag: CancelBag) {
        cancelBag.cancellables.insert(self)
    }
}
