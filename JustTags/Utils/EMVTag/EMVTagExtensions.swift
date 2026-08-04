//
//  EMVTagExtensions.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 08/10/2022.
//

import Foundation
import SwiftyEMVTags
import SwiftyBERTLV

/// The result of resolving a tag conflict between a custom kernel and a built-in one:
/// the custom kernel's meaning is assumed to be a deliberate override, so it's shown as
/// `primary` while the built-in's competing meaning is `hidden` behind a disclosure.
/// When there's no cross-category conflict (all-custom or all-built-in overlap), every
/// meaning stays in `primary` and `hidden` is empty - today's "show as a tie" behavior.
internal struct ResolvedMeanings {
    internal let primary: [EMVTag.DecodedTag]
    internal let hidden: [EMVTag.DecodedTag]
}

extension EMVTag.DecodingResult {

    internal func resolvedMeanings(customKernelIds: Set<String>) -> ResolvedMeanings {
        guard case .multipleKernels(let decodedTags) = self else {
            return .init(primary: [], hidden: [])
        }

        let customTags = decodedTags.filter { customKernelIds.contains($0.kernel) }
        let builtInTags = decodedTags.filter { customKernelIds.contains($0.kernel) == false }

        guard customTags.isEmpty == false, builtInTags.isEmpty == false else {
            return .init(primary: decodedTags, hidden: [])
        }

        return .init(primary: customTags, hidden: builtInTags)
    }

}

extension EMVTag {

    internal func extendedDescription(customKernelIds: Set<String> = []) -> String? {
        switch self.decodingResult {
        case .unknown:
            return nil
        case .singleKernel(let decodedTag):
            if let extendedDescription = decodedTag.result.extendedDescription {
                return extendedDescription
            } else if let firstMeaning = selectedMeanings.first,
                      selectedMeanings.count == 1 {
                return firstMeaning
            } else {
                return nil
            }
        case .multipleKernels:
            let primary = decodingResult.resolvedMeanings(customKernelIds: customKernelIds).primary
            return Set(primary.compactMap(\.result.extendedDescription))
                .joined(separator: ", ")
        }
    }

    internal func name(customKernelIds: Set<String> = []) -> String? {
        switch self.decodingResult {
        case .unknown:
            return nil
        case .singleKernel(let decodedTag):
            return decodedTag.tagInfo.name
        case .multipleKernels:
            let primary = decodingResult.resolvedMeanings(customKernelIds: customKernelIds).primary
            return Set(primary.map(\.tagInfo.name))
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
    
    internal var constructedIds: [EMVTag.ID] {
        switch category {
        case .plain:
            return []
        case .constructed(let subtags):
            return [id] + subtags.flatMap(\.constructedIds)
        }
    }

    internal var fullHexString: String {
        tag.bytes.hexString
    }
    
    internal var valueHexString: String {
        tag.value.hexString
    }
    
}

extension EMVTag {

    func tagValueVM(customKernelIds: Set<String> = []) -> TagValueVM {
        .init(
            value: tag.value.hexStringWithSpaces,
            extendedDescription: extendedDescription(customKernelIds: customKernelIds)
        )
    }

    func tagHeaderVM(customKernelIds: Set<String> = []) -> TagHeaderVM {
        let meanings: [TagHeaderVM.Meaning]
        var hiddenMeanings: [TagHeaderVM.Meaning] = []
        switch decodingResult {
        case .unknown:
            meanings = []
        case .singleKernel(let decodedTag):
            meanings = [.init(name: decodedTag.tagInfo.name, kernel: nil)]
        case .multipleKernels:
            let resolved = decodingResult.resolvedMeanings(customKernelIds: customKernelIds)
            meanings = resolved.primary.map { .init(name: $0.tagInfo.name, kernel: $0.kernel) }
            hiddenMeanings = resolved.hidden.map { .init(name: $0.tagInfo.name, kernel: $0.kernel) }
        }
        return .init(tag: tag.tag.hexString, meanings: meanings, hiddenMeanings: hiddenMeanings)
    }
    
    var asciiValue: String? {
        guard case .singleKernel(let decodedTag) = decodingResult else { return nil }
        return decodedTag.result.asciiValue
    }

    var bytes: [DecodedByteVM]? {
        guard case .singleKernel(let decodedTag) = decodingResult else { return nil }
        let vms = decodedTag.result.decodedByteVMs
        return vms.isEmpty ? nil : vms
    }

    func asciiValue(for kernel: String) -> String? {
        switch decodingResult {
        case .singleKernel(let decodedTag) where decodedTag.kernel == kernel:
            return decodedTag.result.asciiValue
        case .multipleKernels(let decodedTags):
            return decodedTags.first(where: { $0.kernel == kernel })?.result.asciiValue
        default:
            return nil
        }
    }

    func plainTagVM(isEdited: Bool, customKernelIds: Set<String> = []) -> PlainTagVM {
        .init(
            id: id,
            tagCode: tag.tag,
            headerVM: tagHeaderVM(customKernelIds: customKernelIds),
            valueVM: tagValueVM(customKernelIds: customKernelIds),
            canExpand: selectedMeanings.count > 1,
            showsDetails: isUnknown == false,
            selectedMeanings: selectedMeanings,
            isEdited: isEdited,
            asciiValue: asciiValue,
            bytes: bytes
        )
    }

    func constructedTagVM(editedIds: Set<EMVTag.ID>, customKernelIds: Set<String> = []) -> ConstructedTagVM {
        guard case let .constructed(subtags) = category else {
            fatalError("Unable to extract subtags from a plain tag")
        }

        return .init(
            id: id,
            tag: tag.tag.hexString,
            name: name(customKernelIds: customKernelIds),
            headerVM: tagHeaderVM(customKernelIds: customKernelIds),
            valueVM: tagValueVM(customKernelIds: customKernelIds),
            subtags: subtags.map {
                TagRowVM(tag: $0, isSubtag: true, editedIds: editedIds, customKernelIds: customKernelIds)
            },
            showsDetails: isUnknown == false,
            isEdited: editedIds.contains(id) || subtags.contains { editedIds.contains($0.id) }
        )
    }

    func tagInfoVMs(customKernelIds: Set<String> = []) -> [TagInfoVM] {
        switch self.decodingResult {
        case .unknown:
            return []
        case .singleKernel(let decodedTag):
            return [decodedTag.tagInfoVM]
        case .multipleKernels:
            return decodingResult.resolvedMeanings(customKernelIds: customKernelIds).primary.map(\.tagInfoVM)
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
            kernel: kernel
        )
    }
    
    var tagInfoVM: TagInfoVM {
        .init(
            source: tagInfo.source.rawValue,
            format: tagInfo.format,
            kernel: kernel,
            description: tagInfo.description
        )
    }
    
}

extension TagInfo {
    
    var tagInfoVM: TagInfoVM {
        .init(
            source: source.rawValue,
            format: format,
            kernel: kernel,
            description: description
        )
    }
    
}
