//
//  Diff.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 25/04/2022.
//

import Foundation
import SwiftyEMVTags

internal enum TagDiffResult: CustomStringConvertible, Equatable {
    case equal(EMVTag)
    case different([DiffResult], [DiffResult])
    case rightMissing(EMVTag)
    case leftMissing(EMVTag)
    
    var description: String {
        switch self {
        case .equal:
            return "equal"
        case .different:
            return "different"
        case .rightMissing:
            return "right missing"
        case .leftMissing:
            return "left missing"
        }
    }
    
    func byteDiffResults(isLeft: Bool) -> [DiffResult] {
        switch self {
        case .equal(let eMVTag):
            return eMVTag.value.map { _ in .equal }
        case .different(let array, let array2):
            return isLeft ? array : array2
        case .rightMissing(let eMVTag):
            return isLeft ? eMVTag.value.map { _ in .equal } : []
        case .leftMissing(let eMVTag):
            return isLeft ? [] : eMVTag.value.map { _ in .equal }
        }
    }
    
    var isEqual: Bool {
        switch self {
        case .equal: return true
        default: return false
        }
    }
    
}

internal enum DiffResult {
    case equal
    case different
}

extension EMVTag {
    
    static func compare(lhs: EMVTag, rhs: EMVTag) -> TagDiffResult {
        if lhs.tag == rhs.tag {
            // same value
            if lhs.value == rhs.value {
                return .equal(lhs)
                // different value
            } else {
                let res = diffCompare(left: lhs.value, right: rhs.value)
                return .different(res.lhs, res.rhs)
            }
        } else {
            return .rightMissing(lhs)
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
            
            switch diffResult {
            case .equal, .different:
                results.append(diffResult)
                leftIdx += 1
                rightIdx += 1
            case .rightMissing:
                results.append(diffResult)
                leftIdx += 1
            case .leftMissing:
                break
            }
            // append the rest of the right
        } else if leftIdx == lhs.endIndex {
            results.append(
                contentsOf: rhs.suffix(from: rightIdx).map(TagDiffResult.leftMissing)
            )
            rightIdx = rhs.endIndex
            // apend the rest of the left
        } else if rightIdx == rhs.endIndex {
            results.append(
                contentsOf: lhs.suffix(from: leftIdx).map(TagDiffResult.rightMissing)
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
