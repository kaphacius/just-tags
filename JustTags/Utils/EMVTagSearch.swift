//
//  EMVTagSearch.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 08/10/2022.
//

import Foundation
import SwiftyEMVTags

internal protocol Searchable {
    var searchComponents: [String] { get }
}

extension EMVTag: SimpleSearchable, NestedSearchable {

    var searchPair: (id: UUID, comps: Set<String>) {
        (id: self.id, comps: searchComponents)
    }
    
    var searchPairs: [(id: UUID, comps: Set<String>)] {
        [searchPair] + category.searchPairs
    }
    
    func filterNested(
        using words: Set<String>,
        components: [Self.ID: Set<String>]
    ) -> Self {
        switch category {
        case .plain:
            return self
        case .constructed(let subtags):
            let matchingSubtags = filterNestedSearchable(
                initial: subtags,
                components: components,
                words: words
            )
            if matchingSubtags.isEmpty {
                return self
            } else {
                return .init(
                    id: self.id,
                    tag: self.tag,
                    category: .constructed(subtags: matchingSubtags),
                    decodingResult: self.decodingResult
                )
            }
        }
    }
    
}

extension EMVTag: SearchComponentsAware {
    
    internal var searchComponents: Set<String> {
        [
            [tag.tag.hexString],
            category.searchComponents,
            decodingResult.searchComponents
        ]
            .foldToSet()
            .asFlattenedSearchComponents()
    }
    
}

extension EMVTag.DecodingResult: SearchComponentsAware {
    
    internal var searchComponents: Set<String> {
        switch self {
        case .unknown:
            return []
        case .singleKernel(let decodedTag):
            return decodedTag.searchComponents
        case .multipleKernels(let decodedTags):
            return decodedTags.map(\.searchComponents).foldToSet()
        }
    }
    
}

extension EMVTag.Category: SearchComponentsAware {

    internal var searchComponents: Set<String> {
        switch self {
        case .plain:
            return []
        case .constructed(let subtags):
            return subtags.map(\.searchComponents).foldToSet()
        }
    }
    
    internal var searchPairs: [(id: EMVTag.ID, comps: Set<String>)] {
        switch self {
        case .plain:
            return []
        case .constructed(let subtags):
            return subtags.map(\.searchPair)
        }
    }

}

extension EMVTag.DecodedTag: SearchComponentsAware {
    
    internal var searchComponents: Set<String> {
        [
            tagInfo.searchComponents,
            result.searchComponents,
            Set([extendedDescription].compactMap { $0 })
        ].foldToSet()
    }
    
}

extension Result: SearchComponentsAware where Success == [EMVTag.DecodedByte] {
    
    internal var searchComponents: Set<String> {
        switch self {
        case .success(let bytes):
            return bytes.map(\.searchComponents).foldToSet()
        case .failure:
            return []
        }
    }
}

extension EMVTag.DecodedByte: SearchComponentsAware {
    
    internal var searchComponents: Set<String> {
        [
            Set([name].compactMap { $0 }),
            groups.map(\.searchComponents).foldToSet()
        ].foldToSet()
    }
    
}

extension EMVTag.DecodedByte.Group: SearchComponentsAware {
    
    internal var searchComponents: Set<String> {
        [
            Set([name]),
            type.searchComponents
        ].foldToSet()
    }
    
}

extension EMVTag.DecodedByte.Group.GroupType: SearchComponentsAware {
    
    internal var searchComponents: Set<String> {
        switch self {
        case .bitmap(let mappingResult):
            return mappingResult.searchComponents
        case .hex, .RFU, .bool:
            return []
        }
    }
    
}

extension EMVTag.DecodedByte.Group.MappingResult: SearchComponentsAware {
    
    internal var searchComponents: Set<String> {
        Set(mappings.map(\.meaning))
    }
    
}
