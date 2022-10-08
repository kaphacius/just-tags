//
//  EMVTagExtensions.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 08/10/2022.
//

import Foundation
import SwiftyEMVTags

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

    // TODO: decide what is better, protocol or small VM
    var tagValueVM: TagValueVM {
        .init(
            value: tag.value.hexString,
            extendedDescription: extendedDescription
        )
    }

    var tagHeaderVM: TagHeaderVM {
        PrimitiveTagVM.make(
            with: self
        )
    }

}
