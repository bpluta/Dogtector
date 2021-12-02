//
//  Store.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import SwiftUI
import Combine

typealias Store<State> = CurrentValueSubject<State,Never>

extension Store {
    subscript<T>(keyPath: WritableKeyPath<Output, T>) -> T where T: Equatable {
        get { value[keyPath: keyPath] }
        set {
            var value = self.value
            guard value[keyPath: keyPath] != newValue else { return }
            value[keyPath: keyPath] = newValue
            self.value = value
        }
    }
    
    func updates<Value>(for keyPath: KeyPath<Output, Value>) -> AnyPublisher<Value, Failure> where Value: Equatable {
        map(keyPath).removeDuplicates().eraseToAnyPublisher()
    }
    
    func refreshes<Value>(of keyPath: KeyPath<Output, Value>) -> AnyPublisher<Value, Failure> where Value: Equatable  {
        map(keyPath).eraseToAnyPublisher()
    }
}

extension Binding where Value: Equatable {
    func dispatched<State>(to state: Store<State>, _ keyPath: WritableKeyPath<State, Value>) -> Self {
        return onSet { state[keyPath] = $0 }
    }
    
    typealias ValueClosure = (Value) -> Void
    
    func onSet(_ perform: @escaping ValueClosure) -> Self {
        return .init(get: { () -> Value in
            self.wrappedValue
        }, set: { value in
            self.wrappedValue = value
            perform(value)
        })
    }
}
