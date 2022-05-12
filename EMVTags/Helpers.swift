//
//  Helpers.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 25/03/2022.
//

import Foundation
import SwiftyEMVTags
import SwiftyBERTLV
import SwiftUI

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
}

extension EMVTag.Info: Codable {
    
    enum CodingKeys: String, CodingKey {
        case tag
        case name
        case description
        case source
        case format
        case kernel
        case minLength
        case maxLength
        case byteMeaningList
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let tagStringValue = try container.decode(String.self, forKey: .tag)
        guard let tag = UInt64(tagStringValue, radix: 16) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [CodingKeys.tag],
                    debugDescription: "Unable to decode tag with value \(tagStringValue)"
                )
            )
        }
        
        let name = try container.decode(String.self, forKey: .name)
        let description = try container.decode(String.self, forKey: .description)
        let source = try container.decode(EMVTag.Source.self, forKey: .source)
        let format: String = try container.decode(String.self, forKey: .format)
        let kernel = try container.decode(EMVTag.Kernel.self, forKey: .kernel)
        let minLength = try container.decode(String.self, forKey: .minLength)
        let maxLength = try container.decode(String.self, forKey: .maxLength)
        let byteMeaningList = try container.decode([[String]].self, forKey: .byteMeaningList)
        
        self.init(
            tag: tag,
            name: name,
            description: description,
            source: source,
            format: format,
            kernel: kernel,
            minLength: minLength,
            maxLength: maxLength,
            byteMeaningList: byteMeaningList
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(tag.hexString, forKey: .tag)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(source, forKey: .source)
        try container.encode(format, forKey: .format)
        try container.encode(kernel, forKey: .kernel)
        try container.encode(minLength, forKey: .minLength)
        try container.encode(maxLength, forKey: .maxLength)
        try container.encode(byteMeaningList, forKey: .byteMeaningList)
    }
    
}

struct TagInfoContainer: Codable {
    let tags: [EMVTag.Info]
}

extension Array where Self.Element == UInt8 {
    var hexString: String {
        map(\.hexString).joined()
    }
}

private func isLess(lhs: [UInt8], rhs: [UInt8]) -> Bool {
    var isLess: Bool? = nil
    
    for i in 0..<min(lhs.count, rhs.count) {
        if lhs[i] != rhs[i] {
            isLess = lhs[i] < rhs[i]
            break
        }
    }
    
    if let isLess = isLess {
        return isLess
    } else {
        return lhs.count < rhs.count
    }
}

extension EMVTag: Comparable {
    
    public static func < (lhs: EMVTag, rhs: EMVTag) -> Bool {
        if lhs.tag == rhs.tag {
            return isLess(lhs: lhs.value, rhs: rhs.value)
        } else {
            return lhs.tag < rhs.tag
        }
    }
    
}

extension EMVTag {
    
    init(bytes: [UInt8]) {
        try! self.init(tlv: .parse(bytes: bytes).first!)
    }
    
    init(tlv: BERTLV) {
        self.init(
            tlv: tlv,
            info: .unknownInfo(for: tlv.tag),
            subtags: tlv.subTags.map { .init(tlv: $0, info: .unknownInfo(for: $0.tag), subtags: []) }
        )
    }
    
    init(hexString: String) {
        self.init(
            bytes: hexString
                .replacingOccurrences(of: " ", with: "")
                .split(by: 2)
                .compactMap { UInt8($0, radix: 16) }
        )
    }
    
}

extension EMVTag.Info {
    
    fileprivate static func unknownInfo(for tag: UInt64) -> EMVTag.Info {
        .init(
            tag: tag,
            name: "Unknown",
            description: "Unknown",
            source: .unknown,
            format: "Unknown",
            kernel: .general,
            minLength: "Unknown",
            maxLength: "Unknown",
            byteMeaningList: []
        )
    }
    
}

extension Array where Self.Element == EMVTag {
    
    var sortedTags: Self {
        self.sorted(by: <)
    }
    
}

internal struct SelectedTag: EnvironmentKey {
    static let defaultValue: Binding<EMVTag?> = .constant(nil)
}

extension EnvironmentValues {
    internal var selectedTag: Binding<EMVTag?> {
        get { self[SelectedTag.self] }
        set { self[SelectedTag.self] = newValue }
    }
}
