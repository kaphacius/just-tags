//
//  WeakAndStrong.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 28/11/2023.
//

import Foundation

class WNS<T: AnyObject>: Identifiable where T: Identifiable {
    
    internal let id: T.ID
    
    private weak var weak: T?
    private var strong: T?
    
    internal var shouldBeDiscared: Bool {
        // Discard if value is gone or if swap never happened
        strong != nil || weak == nil
    }
    
    internal var value: T? {
        weak ?? strong
    }
    
    internal init(_ value: T) {
        // Be strong in the beginning
        self.strong = value
        self.id = value.id
    }
    
    internal init(weakValue: T) {
        // Be strong in the beginning
        self.weak = weakValue
        self.id = weakValue.id
    }
    
    private func swap() {
        self.weak = self.strong
        self.strong = nil
    }
    
    internal func getWithSwap() -> T? {
        if let strong {
            self.swap()
            return strong
        } else {
            return weak
        }
    }
    
}

extension Array {
    
    func wnsFirst<T>(with id: T.ID) -> T? where Element == WNS<T> {
        self.first(where: { $0.id == id }).flatMap { $0.getWithSwap() }
    }
    
    func wnsFilter<T>(
        _ predicate: Predicate<T>
    ) throws -> [Element] where Element == WNS<T> {
        try self.filter { wns in
            try wns.value.map { try predicate.evaluate($0) } ?? false
        }
    }
    
    mutating func wnsFirst<T>(_ newElement: T) where Element == WNS<T> {
        self.append(.init(newElement))
    }
    
}
