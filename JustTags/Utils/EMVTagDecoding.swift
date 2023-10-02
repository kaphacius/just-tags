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
    
    internal var tagDetailsVMs: [TagDetailsVM] {
        decodingResult.tagDetailsVMs
    }
    
    internal var diffedTagRowVM: DiffedTagRowVM {
        DiffedTag(
            tag: self,
            results: Array(repeating: .equal, count: tag.value.count)
        ).diffedTagRowVM
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
    
    internal var tagDetailsVMs: [TagDetailsVM] {
        switch self {
        case .unknown:
            return []
        case .singleKernel(let decodedTag):
            return [decodedTag.tagDetailsVM]
        case .multipleKernels(let decodedTags):
            return decodedTags.map(\.tagDetailsVM)
        }
    }
    
}

extension Result where Success == [EMVTag.DecodedByte] {
    
    internal var decodedByteVMs: [DecodedByteVM] {
        switch self {
        case .success(let decodedBytes):
            return decodedBytes
                .enumerated()
                .map { $0.element.decodedByteVM(idx: $0.offset) }
        case .failure:
            // TODO: handle error
            return []
        }
    }
    
}

extension EMVTag.DecodedByte {
    
    internal var selectedMeanings: [String] {
        groups.compactMap(\.selectedMeaning)
    }
    
    internal func decodedByteVM(idx: Int) -> DecodedByteVM {
        .init(
            idx: idx,
            name: name,
            rows: decodedRowVMs
        )
    }
    
    internal var decodedRowVMs: [DecodedRowVM] {
        var idx: Int = 0
    
        return groups.flatMap { group in
            let vms = group.decodedRowVMs(startIndex: idx)
            idx += group.width
            return vms
        }
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
    
    internal func decodedRowVMs(startIndex: Int) -> [DecodedRowVM] {
        switch self.type {
        case .bitmap(let mappingResult):
            return mappingResult.decodedRowVMs(
                name: name,
                width: width,
                startIndex: startIndex
            )
        case .bool(let isSelected):
            return [.init(
                meaning: name,
                isSelected: isSelected,
                values: [isSelected ? "1" : "0"],
                startIndex: startIndex
            )]
        case .RFU:
            return [
                .init(
                    meaning: name,
                    isSelected: false,
                    values: pattern.stringBits(startIndex: UInt8.bitWidth - width, width: width),
                    startIndex: startIndex
                )
            ]
        case .hex(let number):
            return [
                .init(
                    meaning: name,
                    isSelected: false,
                    values: number.stringBits(startIndex: startIndex, width: width),
                    startIndex: startIndex
                )
            ]
        }
    }
    
}

extension EMVTag.DecodedByte.Group.MappingResult {
    
    internal var selectedMeaning: String? {
        return mappings[matchIndex].meaning
    }
    
    internal func decodedRowVMs(
        name: String,
        width: Int,
        startIndex: Int
    ) -> [DecodedRowVM] {
        [.init(
            meaning: name,
            isSelected: false,
            values: Array(repeating: lookupSymbol, count: width),
            startIndex: startIndex
        )] + mappings
            .enumerated().map {
                $0.element.decodedRowVM(
                    width: width,
                    startIndex: startIndex,
                    isSelected: $0.offset == matchIndex
                )
            }
    }
    
}

extension EMVTag.DecodedByte.Group.MappingResult.SingleMapping {
    
    internal func decodedRowVM(
        width: Int,
        startIndex: Int,
        isSelected: Bool
    ) -> DecodedRowVM {
        .init(
            meaning: meaning,
            isSelected: isSelected,
            values: pattern.stringBits(startIndex: UInt8.bitWidth - width, width: width),
            startIndex: startIndex
        )
    }
    
}

extension UInt8 {
    
    internal func stringBits(startIndex: Int, width: Int) -> [String] {
        Array(stringBits[startIndex..<startIndex + width])
    }
    
    fileprivate var stringBits: [String] {
        String(self, radix: 2)
            .pad(with: "0", toLength: UInt8.bitWidth)
            .map { String($0) }
    }
    
}
