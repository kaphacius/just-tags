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
            switch decodedTag.result {
            case .bytes(let bytes):
                return bytes.flatMap(\.selectedMeanings)
            case .dol(let decodedDOL):
                return decodedDOL.map(\.description)
            case .asciiValue, .error, .noDecodingInfo, .mapping:
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

extension EMVTag.DecodedTag.DecodingResult {

    internal var asciiValue: String? {
        if case .asciiValue(let value) = self { return value }
        return nil
    }

    internal var hasBytesOrMapping: Bool {
        switch self {
        case .bytes, .mapping: return true
        default: return false
        }
    }

    internal var extendedDescription: String? {
        switch self {
        case .bytes, .dol, .noDecodingInfo:
            return nil
        case .mapping(let string),
                .asciiValue(let string), 
                .error(let string):
            return string
        }
    }
    
    internal var decodedByteVMs: [DecodedByteVM] {
        switch self {
        case .bytes(let bytes):
            return bytes
                .enumerated()
                .map { $0.element.decodedByteVM(idx: $0.offset) }
        case .asciiValue, .dol, .error, .mapping, .noDecodingInfo:
            return []
        }
    }
    
}

extension EMVTag.DecodedByte {
    
    internal var selectedMeanings: [String] {
        groups.compactMap(\.selectedMeaning)
    }
    
    internal func decodedByteVM(idx: Int, isPlaceholder: Bool = false) -> DecodedByteVM {
        .init(
            idx: idx,
            name: name,
            groups: decodedGroupVMs,
            isPlaceholder: isPlaceholder
        )
    }

    internal var decodedGroupVMs: [DecodedGroupVM] {
        var idx: Int = 0
        let fullBits = groups.map { $0.pattern.binaryString(width: $0.width) }.joined()
        let hasEnumeration = groups.contains { if case .enumeration = $0.type { return true }; return false }

        return groups.map { group in
            let vm = group.decodedGroupVM(startIndex: idx, fullBits: fullBits, rfuAsPicker: hasEnumeration)
            idx += group.width
            return vm
        }
    }

}

extension EMVTag.DecodedByte.Group {
    
    internal var selectedMeaning: String? {
        switch self.type {
        case .bool(let result) where result:
            return name
        case .bitmap(let mappingResult), .enumeration(let mappingResult):
            return mappingResult.selectedMeaning
        default:
            return nil
        }
    }

    internal func decodedGroupVM(startIndex: Int, fullBits: String, rfuAsPicker: Bool) -> DecodedGroupVM {
        switch self.type {
        case .enumeration(let mappingResult):
            return .picker(mappingResult.pickerVM(name: name, width: width, startIndex: startIndex, fullBits: fullBits))
        case .RFU where rfuAsPicker:
            return .picker(rfuPickerVM(startIndex: startIndex, fullBits: fullBits))
        default:
            return .rows(decodedRowVMs(startIndex: startIndex))
        }
    }

    private func rfuPickerVM(startIndex: Int, fullBits: String) -> EnumGroupPickerVM {
        EnumGroupPickerVM(
            name: name,
            fullBits: fullBits,
            highlightRange: startIndex..<(startIndex + width),
            currentMeaning: "",
            rows: [],
            startIndex: startIndex,
            width: width,
            isInteractive: false
        )
    }

    internal func decodedRowVMs(startIndex: Int) -> [DecodedRowVM] {
        switch self.type {
        case .bitmap(let mappingResult), .enumeration(let mappingResult):
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

    internal func pickerVM(
        name: String,
        width: Int,
        startIndex: Int,
        fullBits: String
    ) -> EnumGroupPickerVM {
        let rows: [MappingPickerRow] = mappings.compactMap { mapping in
            guard case .concrete(let pattern) = mapping.pattern else { return nil }
            return MappingPickerRow(id: pattern.binaryString(width: width), meaning: mapping.meaning)
        }
        return EnumGroupPickerVM(
            name: name,
            fullBits: fullBits,
            highlightRange: startIndex..<(startIndex + width),
            currentMeaning: selectedMeaning ?? "",
            rows: rows,
            startIndex: startIndex,
            width: width,
            isInteractive: true
        )
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
            values: pattern.stringBits(
                startIndex: UInt8.bitWidth - width,
                width: width,
                isSelected: isSelected
            ),
            startIndex: startIndex
        )
    }
    
}

extension EMVTag.DecodedByte.Group.MappingResult.SingleMapping.Pattern {
    
    internal func stringBits(startIndex: Int, width: Int, isSelected: Bool) -> [String] {
        switch self {
        case .concrete(let pattern):
            return pattern.stringBits(startIndex: startIndex, width: width)
        case .allOtherValues(let value) where isSelected:
            return value.stringBits(startIndex: startIndex, width: width)
        case .allOtherValues:
            return Array(repeating: "x", count: width)
        }
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

    fileprivate func binaryString(width: Int) -> String {
        String(stringBits.suffix(width).joined())
    }

}

extension DecodedDataObject: @retroactive CustomStringConvertible {
    
    public var description: String {
        
        "\(tag.hexString) - \(name), \(expectedLength) byte\(expectedLength == 1 ? "" : "s")"
        
    }
    
}
