//
//  EMVTagSearch.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 08/10/2022.
//

import Foundation
import SwiftyEMVTags

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

extension EMVTag {
    
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

extension EMVTag.DecodingResult {
    
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

extension EMVTag.Category {

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

extension EMVTag.DecodedTag {
    
    internal var searchComponents: Set<String> {
        [
            tagInfo.searchComponents,
            result.searchComponents
        ].foldToSet()
    }
    
}

extension EMVTag.DecodedTag.DecodingResult {
    
    var searchComponents: Set<String> {
        switch self {
        case .bytes(let bytes):
            return bytes.map(\.searchComponents).foldToSet()
        case .mapping(let string):
            return [string]
        case .asciiValue(let value):
            return [value]
        case .dol(let decodedDOL):
            return decodedDOL.map(\.searchComponents).foldToSet()
        case .error:
            return []
        case .noDecodingInfo:
            return []
        }
    }
    
}

extension DecodedDataObject {
    
    var searchComponents: Set<String> {
        [tag.hexString, name]
    }
    
}

extension EMVTag.DecodedByte {
    
    internal var searchComponents: Set<String> {
        [
            Set([name].compactMap { $0 }),
            groups.map(\.searchComponents).foldToSet()
        ].foldToSet()
    }
    
}

extension EMVTag.DecodedByte.Group {
    
    internal var searchComponents: Set<String> {
        [
            Set([name]),
            type.searchComponents
        ].foldToSet()
    }
    
}

extension EMVTag.DecodedByte.Group.GroupType {
    
    internal var searchComponents: Set<String> {
        switch self {
        case .bitmap(let mappingResult):
            return mappingResult.searchComponents
        case .hex, .RFU, .bool:
            return []
        }
    }
    
}

extension EMVTag.DecodedByte.Group.MappingResult {
    
    internal var searchComponents: Set<String> {
        Set(mappings.map(\.meaning))
    }
    
}
