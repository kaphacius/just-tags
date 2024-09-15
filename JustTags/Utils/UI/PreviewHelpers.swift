//
//  PreviewHelpers.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 08/10/2022.
//

import Foundation
import SwiftyEMVTags
import SwiftyBERTLV

private let tagDecoder = try! TagDecoder.defaultDecoder()

internal enum PreviewHelpers {
    
    internal static let kernelInfoRepo: KernelInfoRepo = .init(handler: tagDecoder)!
    internal static let tagMappingRepo: TagMappingRepo = .init(handler: tagDecoder.tagMapper)!
    
}

extension BERTLV {
    
    internal static let mockTLV = try! BERTLV
        .parse(bytes: [0x9f, 0x33, 0x03, 0x20, 0x08, 0xC8])
        .first!
    
    internal static let mockTLVExtended = try! BERTLV
        .parse(bytes: [0x5f, 0x2a, 0x02, 0x09, 0x78])
        .first!
    
    internal static let mockTLVConstructed = try! BERTLV
        .parse(bytes: [0xe1, 0x0b, 0x9f, 0x33, 0x03, 0x28, 0x08, 0xC8, 0x5F, 0x2A, 0x02, 0x09, 0x78])
        .first!
    
    internal static let mockTLVMultipleKernels = try! BERTLV
        .parse(bytes: [0x5f, 0x34, 0x02, 0xff, 0xaa])
        .first!
    
    internal static let mockTLVDiffLeft = try! BERTLV
        .parse(bytes: [
            0x9f, 0x33, 0x03, 0x20, 0x08, 0xC8,
            0xC1, 0x03, 0xAA, 0xBB, 0xCC,
            0xC2, 0x03, 0xAA, 0xBB, 0xCC
        ])
    
    internal static let mockTLVDiffRight = try! BERTLV
        .parse(bytes: [
            0x9f, 0x33, 0x03, 0x20, 0x08, 0xA8,
            0xC2, 0x03, 0xAA, 0xBB, 0xCC,
            0xC3, 0x03, 0xAA, 0xCC, 0xCC
        ])
    
}

extension EMVTag {
    
    internal static let mockTag = tagDecoder.decodeBERTLV(.mockTLV)
    internal static let mockTagExtended = tagDecoder.decodeBERTLV(.mockTLVExtended)
    internal static let mockTagMultipleKernels = tagDecoder.decodeBERTLV(.mockTLVMultipleKernels)
    internal static let mockTagConstructed = tagDecoder.decodeBERTLV(.mockTLVConstructed)
    internal static let mockDiffPair = (
        BERTLV.mockTLVDiffLeft.map(tagDecoder.decodeBERTLV(_:)),
        BERTLV.mockTLVDiffRight.map(tagDecoder.decodeBERTLV(_:))
    )
    
}

extension PlainTagVM {
    
    static func make(
        with tag: EMVTag,
        canExpand: Bool = false,
        showsDetails: Bool = true
    ) -> PlainTagVM {
        .init(
            id: tag.id,
            headerVM: tag.tagHeaderVM,
            valueVM: tag.tagValueVM,
            canExpand: canExpand,
            showsDetails: showsDetails,
            selectedMeanings: tag.selectedMeanings
        )
    }
    
}

extension ConstructedTagVM {
    
    static func make(
        with tag: EMVTag
    ) -> ConstructedTagVM {
        guard case .constructed = tag.category else {
            fatalError("Provided tag is not constructed")
        }
        
        return tag.constructedTagVM
    }
    
}

extension KernelSelectionRowVM {
    
    static var mockShortVM: KernelSelectionRowVM = .init(
        id: "Kernel 2 for MasterCards AIDs",
        name: "kernel2"
    )
    
    static var mockLongVM: KernelSelectionRowVM = .init(
        id: "Some custom tags for configuration",
        name: "some_config"
    )
    
}
