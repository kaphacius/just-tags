//
//  TagDecodingInfoSearch.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 23/01/2023.
//

import Foundation
import SwiftyEMVTags

extension TagDecodingInfo: Searchable {
    
    internal var searchPair: (Int, String) {
        (hashValue, searchString)
    }
    
    internal var searchComponents: [String] {
        [
            info.searchComponents,
            bytes.flatMap(\.searchComponents)
        ].flatMap { $0 }
    }
    
    internal var searchString: String {
        searchComponents
            .joined(separator: " ")
            .lowercased()
    }
    
}

extension TagInfo: Searchable {
    
    internal var searchComponents: [String] {
        [
            tag.hexString,
            name,
            description,
            source.rawValue,
            format,
            kernel
        ]
    }
    
}

extension ByteInfo: Searchable {
    
    internal var searchComponents: [String] {
        [
            [name].compactMap { $0 },
            groups.flatMap(\.searchComponents)
        ].flatMap { $0 }
    }
    
}

extension ByteInfo.Group: Searchable {
    
    internal var searchComponents: [String] {
        [
            [name],
            type.searchComponents
        ].flatMap { $0 }
    }
    
}

extension ByteInfo.Group.MappingType: Searchable {
    
    var searchComponents: [String] {
        switch self {
        case .RFU, .hex, .bool:
            return []
        case .bitmap(let mappings):
            return mappings.flatMap(\.searchComponents)
        }
    }
    
}

extension ByteInfo.Group.Mapping: Searchable {
    
    var searchComponents: [String] {
        [meaning]
    }
    
}
