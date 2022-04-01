//
//  Helpers.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 25/03/2022.
//

import Foundation
import SwiftyEMVTags
import SwiftyBERTLV

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

