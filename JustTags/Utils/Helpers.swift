//
//  Helpers.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 25/03/2022.
//

import Foundation
import SwiftyEMVTags
import SwiftyBERTLV
import SwiftUI

internal struct JustTagsError: Error {
    
    internal let title: String
    internal let message: String
    
    init(
        title: String = "An error!",
        message: String
    ) {
        self.title = title
        self.message = message
    }
    
}

extension String {
    func split(by length: Int) -> [String] {
        var startIndex = self.startIndex
        var results = [Substring]()
        
        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            results.append(self[startIndex..<endIndex])
            startIndex = endIndex
        }
        
        return results.map { String($0) }
    }
    
    static let uknownTag = "Unknown tag"
}

extension Array where Self.Element == UInt8 {
    var hexString: String {
        map(\.hexString).joined()
    }
}

extension Array where Self.Element == EMVTag {
    var hexString: String {
        map(\.fullHexString).joined()
    }
}

extension EMVTag: Comparable {

    public static func < (lhs: EMVTag, rhs: EMVTag) -> Bool {
        if lhs.tag.tag == rhs.tag.tag {
            return lhs.tag.value < rhs.tag.value
        } else {
            return lhs.tag.tag < rhs.tag.tag
        }
    }

}

extension Int {
    
    public var hexString: String {
        String(format: "%02X", UInt64(self))
    }
    
}

extension Array where Self.Element == EMVTag {

    var sortedTags: Self {
        self.sorted()
    }

}

extension Array: Comparable where Self.Element == UInt8 {
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        for i in 0..<Swift.min(lhs.count, rhs.count) {
            if lhs[i] != rhs[i] {
                return lhs[i] < rhs[i]
            }
        }
        
        return lhs.count < rhs.count
    }
    
}

extension NSPasteboard {
    
    static func copyString(_ string: String) {
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString(string, forType: .string)
    }
    
    static var string: String? {
        NSPasteboard.general.string(forType: .string)
    }
    
}

internal func onMain(_ execute: @escaping () -> Void) {
    DispatchQueue.main.async {
        execute()
    }
}

internal func onMain(seconds delay: TimeInterval, execute: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(
        deadline: .now() + .milliseconds(Int(delay) * 1000),
        execute: execute
    )
}

internal func t2FlatMap<T, U>(_ arg: (T?, U?)) -> (T, U)? {
    if let foo = arg.0,
       let bar = arg.1 {
        return (foo, bar)
    } else {
        return nil
    }
}

//optionals
extension Optional {
    func get(orElse defaultValue: @autoclosure () -> Wrapped) -> Wrapped {
        self ?? defaultValue()
    }
    
    func get(orElseO defaultValue: @autoclosure () -> Optional<Wrapped>) -> Optional<Wrapped> {
        self ?? defaultValue()
    }
}

extension Optional where Wrapped: Collection {
    var notEmpty: Bool {
        self.map(\.isEmpty).map { $0 == false } ?? false
    }
    
    var isEmptyO: Bool {
        self.map(\.isEmpty) ?? true
    }
    
    var moreThanOne: Bool {
        self.map(\.count).map { $0 > 1 } ?? false
    }
}

extension Optional where Wrapped == String {
    func getOrEmpty() -> Wrapped {
        return self != nil ? self.unsafelyUnwrapped : ""
    }
}

extension EMVTag {
    
    func matching(id: Self.ID) -> EMVTag? {
        if self.id == id { return self }
        
        switch self.category {
        case .constructed(let subtags):
            return subtags
                .lazy
                .compactMap { $0.matching(id: id) }
                .first
        case .plain:
            return nil
        }
        
    }
    
}

extension Array where Element == EMVTag {
    
    func first(with id: EMVTag.ID) -> Element? {
        self
            .lazy
            .compactMap { $0.matching(id: id) }
            .first
    }
    
}

extension Array where Element: Identifiable {
    
    func firstIndex(with id: Element.ID) -> Int? {
        firstIndex(where: { $0.id == id })
    }
    
    @discardableResult
    mutating func removeFirst(with id: Element.ID) -> Element? {
        if let idx = firstIndex(with: id) {
            remove(at: idx)
        }
        
        return nil
    }
    
}

extension String {
    func pad(with character: String, toLength length: Int) -> String {
        let padCount = length - self.count
        guard padCount > 0 else { return self }
        
        return String(repeating: character, count: padCount) + self
    }
}
