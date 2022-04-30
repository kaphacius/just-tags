//
//  Diff.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 25/04/2022.
//

import Foundation
import SwiftyEMVTags

typealias DiffedTag = (tag: EMVTag, diff: [DiffResult])

internal struct DiffedTagPair {
    
    internal let lhs: DiffedTag?
    internal let rhs: DiffedTag?
    internal let isEqual: Bool
    
    internal init(lhs: DiffedTag?, rhs: DiffedTag?) {
        self.lhs = lhs
        self.rhs = rhs
        switch (lhs, rhs) {
            case (let lhs?, .some):
                self.isEqual = lhs.diff.contains(.different) == false
            default:
                self.isEqual = false
        }
    }
    
}

typealias DiffedByte = (byte: UInt8, result: DiffResult)

internal enum TagDiffResult {
    case equal(EMVTag)
    case different([DiffedTag?])
    
    var isDifferent: Bool {
        switch self {
        case .equal: return false
        case .different: return true
        }
    }
    
    var diffedPair: DiffedTagPair {
        switch self {
        case .equal(let tag):
            let part = (tag, Array(repeating: DiffResult.equal, count: tag.value.count))
            return .init(lhs: part, rhs: part)
        case .different(let tags):
            return .init(
                lhs: tags.first.flatMap { $0 },
                rhs: tags.last.flatMap { $0 }
            )
        }
    }
}

internal enum DiffResult: Equatable {
    case equal
    case different
}

extension EMVTag {
    
    static func compare3(lhs: EMVTag, rhs: EMVTag) -> TagDiffResult {
        // tags are the same
        if lhs.tag == rhs.tag {
            if lhs.value == rhs.value {
                return .equal(lhs)
            } else {
                let res = diffCompare(left: lhs.value, right: rhs.value)
                return .different([(lhs, res.lhs), (rhs, res.rhs)])
            }
        } else if lhs.tag < rhs.tag {
            // tags are different. left is less. fill the left tags result with different, leave the rigth result empty to move left forward
            return .different(
                [
                    (lhs, .init(repeating: .different, count: lhs.value.count)),
                    nil
                ]
            )
        } else {
            // tags are different. left is more. fill the right tags result with different, leave the left result empty to move right forward
            return .different(
                [
                    nil,
                    (rhs, .init(repeating: .different, count: rhs.value.count))
                ]
            )
        }
    }
    
}

func diffCompareTags(lhs: [EMVTag], rhs: [EMVTag]) -> [TagDiffResult] {
    var leftIdx = lhs.startIndex
    var rightIdx = rhs.startIndex
    var results = [TagDiffResult]()
    
    while leftIdx != lhs.endIndex || rightIdx != rhs.endIndex {
        // elements from both are available
        if leftIdx < lhs.endIndex && rightIdx < rhs.endIndex {
            let currentL = lhs[leftIdx]
            let currentR = rhs[rightIdx]
            
            let diffResult = EMVTag.compare3(lhs: currentL, rhs: currentR)
            results.append(diffResult)
            
            switch diffResult {
                // equal tags
            case .equal:
                leftIdx += 1
                rightIdx += 1
                // tags are different, right is missing, movin the left pointer forward
            case .different(let results) where results[1] == nil:
                leftIdx += 1
                // tags are different, left is missing, movin the right pointer forward
            case .different(let results) where results[0] == nil:
                rightIdx += 1
                // tags are same, values are different, moving both pointers forward
            case .different:
                leftIdx += 1
                rightIdx += 1
            }
        } else if leftIdx == lhs.endIndex {
            // no more tags on the left, append the rest of the right
            results.append(
                contentsOf: rhs.suffix(from: rightIdx).map { tag in
                    // fill the right tags result with different, leave the rigth result empty
                        .different(
                            [
                                nil,
                                (tag, .init(repeating: .different, count: tag.value.count))
                            ]
                        )
                }
            )
            rightIdx = rhs.endIndex
        } else if rightIdx == rhs.endIndex {
            // no more tags on the left, append the rest of the right
            results.append(
                contentsOf: lhs.suffix(from: leftIdx).map { tag in
                    // fill the left tags result with different, leave the rigth result empty
                        .different(
                            [
                                (tag, .init(repeating: .different, count: tag.value.count)),
                                nil
                            ]
                        )
                }
            )
            leftIdx = lhs.endIndex
        }
    }
    
    return results
}

func diffCompare<T: Equatable>(
    left: [T], right: [T]
) -> (lhs: [DiffResult], rhs: [DiffResult]) {
    var leftIdx = left.startIndex
    var rightIdx = right.startIndex
    var results = (lhs: [DiffResult](), rhs: [DiffResult]())
    
    while leftIdx != left.endIndex || rightIdx != right.endIndex {
        // elements from both are available
        if leftIdx < left.endIndex && rightIdx < right.endIndex {
            let currentL = left[leftIdx]
            let currentR = right[rightIdx]
            
            let diffResult: DiffResult = currentL == currentR ? .equal : .different
            results.lhs.append(diffResult)
            results.rhs.append(diffResult)
            leftIdx += 1
            rightIdx += 1
            // append the rest of the right
        } else if leftIdx == left.endIndex {
            results.rhs.append(
                contentsOf: right.suffix(from: rightIdx).map { _ in DiffResult.different }
            )
            rightIdx = right.endIndex
            // apend the rest of the left
        } else if rightIdx == right.endIndex {
            results.lhs.append(
                contentsOf: left.suffix(from: leftIdx).map { _ in DiffResult.different }
            )
            leftIdx = left.endIndex
        }
    }
    
    return results
}
