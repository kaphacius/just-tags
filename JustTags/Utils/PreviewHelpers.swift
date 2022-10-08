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

extension BERTLV {
    
    internal static let mockTLV = try! BERTLV
        .parse(bytes: [0x9f, 0x33, 0x03, 0x28, 0x08, 0xC8])
        .first!
    
    internal static let mockTLVExtended = try! BERTLV
        .parse(bytes: [0x5f, 0x2a, 0x02, 0x09, 0x78])
        .first!
    
    internal static let mockTLVConstructed = try! BERTLV
        .parse(bytes: [0xe1, 0x06, 0x9f, 0x33, 0x03, 0x28, 0x08, 0xC8])
        .first!
    
}

extension EMVTag {
    
    internal static let mockTag = tagDecoder.decodeBERTLV(.mockTLV)
    internal static let mockTagExtended = tagDecoder.decodeBERTLV(.mockTLVExtended)
    internal static let mockTagConstructed = tagDecoder.decodeBERTLV(.mockTLVConstructed)
    
}

extension PrimitiveTagVM {
    
    static func make(
        with tag: EMVTag,
        id: UUID = .init(),
        canExpand: Bool = false,
        showsDetails: Bool = true
    ) -> PrimitiveTagVM {
        .init(
            id: .init(),
            tag: tag.tag.tag.hexString,
            name: tag.name,
            valueVM: tag.tagValueVM,
            canExpand: canExpand,
            showsDetails: showsDetails
        )
    }
    
}

extension ConstructedTagVM {
    
    static func make(
        with tag: EMVTag
    ) -> ConstructedTagVM {
        guard case .constructed(let subtags) = tag.category else {
            fatalError("Provided tag is not constructed")
        }
        
        return .init(
            id: .init(),
            tag: tag,
            subtags: subtags
        )
    }
    
}

extension TagRowVM {
    
    static func make(
        with tag: EMVTag
    ) -> TagRowVM {
        .init(id: .init(), tag: tag)
    }
    
}
