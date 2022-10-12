//
//  EMVTagExtensions.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 08/10/2022.
//

import Foundation
import SwiftyEMVTags
import SwiftyBERTLV

extension EMVTag {
    
    internal var extendedDescription: String? {
        switch self.decodingResult {
        case .unknown:
            return nil
        case .singleKernel(let decodedTag):
            return decodedTag.extendedDescription
        case .multipleKernels(let decodedTags):
            return Set(decodedTags.compactMap(\.extendedDescription))
                .joined(separator: ", ")
        }
    }
    
    internal var name: String {
        switch self.decodingResult {
        case .unknown:
            return ""
        case .singleKernel(let decodedTag):
            return decodedTag.tagInfo.name
        case .multipleKernels(let decodedTags):
            return Set(decodedTags.map(\.tagInfo.name))
                .joined(separator: ", ")
        }
    }
    
    internal var isUnknown: Bool {
        switch decodingResult {
        case .unknown:
            return true
        case .multipleKernels, .singleKernel:
            return false
        }
    }
    
    internal var isConstructed: Bool {
        switch category {
        case .plain:
            return false
        case .constructed:
            return true
        }
    }
    
    internal var constructedIds: [EMVTag.ID] {
        switch category {
        case .plain:
            return []
        case .constructed(let subtags):
            return [id] + subtags.flatMap(\.constructedIds)
        }
    }
    
    internal var fullHexString: String {
        [
            tag.tag.hexString,
            tag.lengthBytes.hexString,
            tag.value.hexString
        ].joined()
    }
    
    internal var valueHexString: String {
        tag.value.hexString
    }
    
}

extension EMVTag {

    var tagValueVM: TagValueVM {
        .init(
            value: tag.value.hexString,
            extendedDescription: extendedDescription
        )
    }

    var tagHeaderVM: TagHeaderVM {
        .init(
            tag: tag.tag.hexString,
            name: name
        )
    }
    
    var plainTagVM: PlainTagVM {
        .init(
            id: id,
            headerVM: tagHeaderVM,
            valueVM: tagValueVM,
            canExpand: selectedMeanings.isEmpty == false,
            showsDetails: isUnknown == false,
            selectedMeanings: selectedMeanings
        )
    }
    
    var constructedTagVM: ConstructedTagVM {
        guard case let .constructed(subtags) = category else {
            fatalError("Unable to extract subtags from a plain tag")
        }
        
        return .init(
            id: id,
            tag: tag.tag.hexString,
            name: name,
            headerVM: tagHeaderVM,
            valueVM: tagValueVM,
            subtags: subtags.map(\.tagRowVM)
        )
    }
    
    var tagRowVM: TagRowVM {
        .init(tag: self)
    }
    
    var tagInfoVMs: [TagInfoVM] {
        switch self.decodingResult {
        case .unknown:
            return []
        case .singleKernel(let decodedTag):
            return [decodedTag.tagInfoVM]
        case .multipleKernels(let decodedTags):
            return decodedTags.map(\.tagInfoVM)
        }
    }

}

extension EMVTag.DecodedTag {
    
    var tagDetailsVM: TagDetailsVM {
        .init(
            tag: tagInfo.tag.hexString,
            name: tagInfo.name,
            info: tagInfoVM,
            bytes: result.decodedByteVMs,
            kernel: kernelName
        )
    }
    
    var tagInfoVM: TagInfoVM {
        .init(
            source: tagInfo.source.rawValue,
            format: tagInfo.format,
            kernel: kernelName,
            description: tagInfo.description
        )
    }
    
}
