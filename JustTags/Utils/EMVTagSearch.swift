//
//  EMVTagSearch.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 08/10/2022.
//

import Foundation
import SwiftyEMVTags

private protocol Searchable {
    var searchComponents: [String] { get }
}

extension EMVTag: Searchable {
    
    fileprivate var searchComponents: [String] {
        [
            [tag.tag.hexString],
            category.searchComponents,
            decodingResult.searchComponents
        ].flatMap { $0 }
    }
    
    internal var searchString: String {
        searchComponents
            .joined()
            .lowercased()
    }
    
    // TODO: add filtering subtags to searched tags
//    func filtered(with string: String, matchingTags: Set<EMVTag.ID>) -> EMVTag {
//        if isConstructed {
//            return .init(
//                id: self.id,
//                tag: self.tag,
//                name: self.name,
//                description: self.description,
//                source: self.source,
//                format: self.format,
//                kernel: self.kernel,
//                isConstructed: self.isConstructed,
//                value: self.value,
//                lengthBytes: self.lengthBytes,
//                subtags: self.subtags.filter { matchingTags.contains($0.id) },
//                decodedMeaningList: self.decodedMeaningList
//            )
//        } else {
//            return self
//        }
//    }
    
}

extension EMVTag.DecodingResult: Searchable {
    
    fileprivate var searchComponents: [String] {
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
    
    fileprivate var searchComponents: [String] {
        switch self {
        case .plain:
            return []
        case .constructed(let subtags):
            return subtags.flatMap(\.searchComponents)
        }
    }
    
}


extension EMVTag.DecodedTag: Searchable {
    
    fileprivate var searchComponents: [String] {
        [
            tagInfo.searchComponents,
            result.searchComponents,
            [extendedDescription].compactMap { $0 }
        ]
            .flatMap { $0 }
    }
    
}

extension Result: Searchable where Success == [EMVTag.DecodedByte] {
    
    fileprivate var searchComponents: [String] {
        switch self {
        case .success(let bytes):
            return bytes.flatMap(\.searchComponents)
        case .failure:
            return []
        }
    }
}

extension EMVTag.DecodedByte: Searchable {
    
    fileprivate var searchComponents: [String] {
        [
            [name].compactMap { $0 },
            groups.map(\.searchComponents).flatMap { $0 }
        ].flatMap { $0 }
    }
    
}

extension EMVTag.DecodedByte.Group: Searchable {
    
    fileprivate var searchComponents: [String] {
        [
            [name],
            type.searchComponents
        ].flatMap { $0 }
    }
    
}

extension EMVTag.DecodedByte.Group.GroupType: Searchable {
    
    fileprivate var searchComponents: [String] {
        switch self {
        case .bitmap(let mappingResult):
            return mappingResult.searchComponents
        case .hex, .RFU, .bool:
            return []
        }
    }
    
}

extension EMVTag.DecodedByte.Group.MappingResult: Searchable {
    
    fileprivate var searchComponents: [String] {
        mappings.map(\.meaning)
    }
    
}

extension TagInfo: Searchable {
    
    fileprivate var searchComponents: [String] {
        [
            name,
            description,
            source.rawValue,
            format,
            kernel
        ]
    }
    
}
