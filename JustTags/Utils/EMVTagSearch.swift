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

extension EMVTag: Searchable {
    
    internal var searchPairs: [(Self.ID, String)] {
        [searchPair] + category.searchPairs
    }
    
    internal var searchPair: (Self.ID, String) {
        (id, searchString)
    }
    
    internal var searchComponents: [String] {
        [
            [tag.tag.hexString],
            category.searchComponents,
            decodingResult.searchComponents
        ].flatMap { $0 }
    }
    
    private var searchString: String {
        searchComponents
            .joined()
            .lowercased()
    }
    
    internal func matching(
        searchText: String,
        tagDescriptions: Dictionary<Self.ID, String>
    ) -> EMVTag? {
        tagDescriptions[id].flatMap { searchString in
            guard searchString.contains(searchText) else {
                return nil
            }
            
            switch category {
            case .plain:
                return self
            case .constructed(let subtags):
                let matchingSubtags = subtags.compactMap { subtag in
                    subtag.matching(
                        searchText: searchText, tagDescriptions: tagDescriptions)
                }
                
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
    
}

extension EMVTag.DecodingResult: Searchable {
    
    internal var searchComponents: [String] {
        switch self {
        case .unknown:
            return []
        case .singleKernel(let decodedTag):
            return decodedTag.searchComponents
        case .multipleKernels(let decodedTags):
            return decodedTags.flatMap(\.searchComponents)
        }
    }
    
}

extension EMVTag.Category: Searchable {
    
    internal var searchComponents: [String] {
        switch self {
        case .plain:
            return []
        case .constructed(let subtags):
            return subtags.flatMap(\.searchComponents)
        }
    }
    
    internal var searchPairs: [(EMVTag.ID, String)] {
        switch self {
        case .plain:
            return []
        case .constructed(let subtags):
            return subtags.map(\.searchPair)
        }
    }
    
}


extension EMVTag.DecodedTag: Searchable {
    
    internal var searchComponents: [String] {
        [
            tagInfo.searchComponents,
            result.searchComponents,
            [extendedDescription].compactMap { $0 }
        ].flatMap { $0 }
    }
    
}

extension Result: Searchable where Success == [EMVTag.DecodedByte] {
    
    internal var searchComponents: [String] {
        switch self {
        case .success(let bytes):
            return bytes.flatMap(\.searchComponents)
        case .failure:
            return []
        }
    }
}

extension EMVTag.DecodedByte: Searchable {
    
    internal var searchComponents: [String] {
        [
            [name].compactMap { $0 },
            groups.map(\.searchComponents).flatMap { $0 }
        ].flatMap { $0 }
    }
    
}

extension EMVTag.DecodedByte.Group: Searchable {
    
    internal var searchComponents: [String] {
        [
            [name],
            type.searchComponents
        ].flatMap { $0 }
    }
    
}

extension EMVTag.DecodedByte.Group.GroupType: Searchable {
    
    internal var searchComponents: [String] {
        switch self {
        case .bitmap(let mappingResult):
            return mappingResult.searchComponents
        case .hex, .RFU, .bool:
            return []
        }
    }
    
}

extension EMVTag.DecodedByte.Group.MappingResult: Searchable {
    
    internal var searchComponents: [String] {
        mappings.map(\.meaning)
    }
    
}
