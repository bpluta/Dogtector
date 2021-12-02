//
//  PublisherExtension.swift
//  Dogtector
//
//  Created by Bartłomiej Pluta
//

import Combine

extension Publisher {
    func unwrap<T>(orThrow error: Failure) -> Publishers.TryMap<Self, T> where Output == Optional<T> {
        tryMap { output in
            guard let output = output else { throw error }
            return output
        }
    }
}
