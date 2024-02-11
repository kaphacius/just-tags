//
//  Diff.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 25/04/2022.
//

import Foundation
import SwiftyEMVTags

typealias TagPair = (lhs: [EMVTag], rhs: [EMVTag])

internal struct DiffedTag {
    internal let tag: EMVTag
    internal let results: [DiffResult]
    
    var diffedTagRowVM: DiffedTagRowVM {
        .init(
            id: tag.id,
            headerVM: tag.tagHeaderVM,
            valueVM: .init(value: tag.tag.value, results: results),
            fullHexString: tag.fullHexString,
            valueHexString: tag.tag.value.hexString
        )
    }
}

internal struct DiffedTagPair {
    internal let lhs: DiffedTag?
    internal let rhs: DiffedTag?
    internal let isEqual: Bool
    
    internal init(lhs: DiffedTag?, rhs: DiffedTag?) {
        self.lhs = lhs
        self.rhs = rhs
        switch (lhs, rhs) {
        case (let lhs?, let rhs?):
            self.isEqual = lhs.results.equalDiff && rhs.results.equalDiff
        default:
            self.isEqual = false
        }
    }
    
}

internal enum TagDiffResult {
    case equal(EMVTag)
    case different([DiffedTag?])
    
    var diffedPair: DiffedTagPair {
        switch self {
        case .equal(let tag):
            let part: DiffedTag = .init(
                tag: tag,
                results: Array(repeating: DiffResult.equal, count: tag.tag.value.count)
            )
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
    
    static func compare(lhs: EMVTag, rhs: EMVTag) -> TagDiffResult {
        // tags are the same
        if lhs.tag.tag == rhs.tag.tag {
            if lhs.tag.value == rhs.tag.value {
                return .equal(lhs)
            } else {
                let res = diffCompare(left: lhs.tag.value, right: rhs.tag.value)
                return .different(
                    [.init(tag: lhs, results: res.lhs), .init(tag: rhs, results: res.rhs)]
                )
            }
        } else if lhs.tag.tag < rhs.tag.tag {
            // tags are different. left is less. fill the left tags result with different, leave the right result empty to move left forward
            return .different(
                [
                    .init(tag: lhs, results: .init(repeating: .different, count: lhs.tag.value.count)),
                    nil
                ]
            )
        } else {
            // tags are different. left is more. fill the right tags result with different, leave the left result empty to move right forward
            return .different(
                [
                    nil,
                    .init(tag: rhs, results: .init(repeating: .different, count: rhs.tag.value.count))
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
            
            let diffResult = EMVTag.compare(lhs: currentL, rhs: currentR)
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
                                .init(tag: tag, results: .init(repeating: .different, count: tag.tag.value.count))
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
                                .init(tag: tag, results: .init(repeating: .different, count: tag.tag.value.count)),
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

extension Array where Element == DiffResult {
    
    fileprivate var equalDiff: Bool {
        contains(.different) == false
    }
    
}

internal enum Diff {

    static func diff(tags: [[EMVTag]], onlyDifferent: Bool) -> [DiffedTagPair] {
        guard tags.isEmpty == false else {
            return []
        }
        
        if tags.count == 1 {
            return tags[0].map(TagDiffResult.equal).map(\.diffedPair)
        }
        
        let result = diffCompareTags(lhs: tags[0], rhs: tags[1]).map(\.diffedPair)
        
        if onlyDifferent == false {
            return result
        } else {
            return result.filter { $0.isEqual == false }
        }
    }
    
}
