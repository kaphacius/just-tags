//
//  TagDecodingInfoSearch.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 23/01/2023.
//

import Foundation
import SwiftyEMVTags

extension TagDecodingInfo: PrioritySearchable {
    
    var searchPair: (hash: Int, comps: PrioritySearchComponents) {
        (
            hash: hashValue,
            comps: .init(
                primary: primarySearchComponents,
                secondary: secondarySearhComponents
            )
        )
    }
    
    private var primarySearchComponents: Set<String> {
        Set([info.tag.hexString, info.name])
            .asFlattenedSearchComponents()
    }
    
    private var secondarySearhComponents: Set<String> {
        [[info.searchComponents], bytes.map(\.searchComponents)]
            .flatMap { $0 }
            .foldToSet()
            .asFlattenedSearchComponents()
    }
    
}

extension TagDecodingInfo: SearchComponentsAware {
    
    internal var searchComponents: Set<String> {
        [
            [info.searchComponents],
            bytes.map(\.searchComponents)
        ]
            .flatMap { $0 }
            .foldToSet()
    }
    
}

extension TagInfo: SearchComponentsAware {
    
    internal var searchComponents2: [String] {
        [
            tag.hexString,
            name,
            description,
            source.rawValue,
            format,
            kernel
        ]
    }
    
    internal var searchComponents: Set<String> {
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

extension ByteInfo: SearchComponentsAware {
    
    internal var searchComponents: Set<String> {
        groups
            .map(\.searchComponents)
            .foldToSet()
            .union([name].compactMap {$0} )
    }
    
}

extension ByteInfo.Group: SearchComponentsAware {
    
    internal var searchComponents: Set<String> {
        type.searchComponents.union([name])
    }
    
}

extension ByteInfo.Group.MappingType: SearchComponentsAware {
    
    internal var searchComponents: Set<String> {
        switch self {
        case .RFU, .hex, .bool:
            return []
        case .bitmap(let mappings):
            return Set(mappings.flatMap(\.searchComponents))
        }
    }
    
}

extension ByteInfo.Group.Mapping: SearchComponentsAware {
    
    internal var searchComponents: Set<String> {
        [meaning]
    }
    
}
