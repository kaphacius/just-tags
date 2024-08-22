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
    
    internal init(stongValue value: T) {
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
    
    func pruned<T>() -> Self where Element == WNS<T> {
        self.filter { $0.shouldBeDiscared == false }
    }
    
    mutating func prune<T>() where Element == WNS<T> {
        self = self.pruned()
    }
    
}
