//
//  EMVTagDecoding.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 08/10/2022.
//

import Foundation
import SwiftyEMVTags

extension EMVTag {
    
    internal var selectedMeanings: [String] {
        decodingResult.selectedMeanings
    }
    
}

extension EMVTag.DecodingResult {
    
    internal var selectedMeanings: [String] {
        switch self {
        case .unknown:
            return []
        case .singleKernel(let decodedTag):
            if let result = try? decodedTag.result.get() {
                return result.flatMap(\.selectedMeanings)
            } else {
                return []
            }
        case .multipleKernels:
            return []
        }
    }
    
}

extension EMVTag.DecodedByte {
    
    internal var selectedMeanings: [String] {
        groups.compactMap(\.selectedMeaning)
    }
    
}

extension EMVTag.DecodedByte.Group {
    
    internal var selectedMeaning: String? {
        switch self.type {
        case .bool(let result) where result:
            return name
        case .bitmap(let mappingResult):
            return mappingResult.selectedMeaning
        default:
            return nil
        }
    }
    
}

extension EMVTag.DecodedByte.Group.MappingResult {
    
    internal var selectedMeaning: String? {
        return mappings[matchIndex].meaning
    }
    
}
