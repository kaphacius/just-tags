//
//  DiffView.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 15/04/2022.
//

import SwiftUI
import SwiftyEMVTags

struct DiffView2: View {
    
    static let left: [EMVTag] = [
        .init(bytes: [0x9F, 0x33, 0x03, 0x60, 0x28, 0xC8]),
        .init(bytes: [0xC1, 0x03, 0xFF, 0xAA, 0xBB]),
        .init(bytes: [0xC1, 0x01, 0x01])
    ]
    static let right: [EMVTag] = [
        .init(bytes: [0x9F, 0x33, 0x03, 0x60, 0x48, 0xB8]),
        .init(bytes: [0xC1, 0x02, 0xAA, 0xBB]),
        .init(bytes: [0x5A, 0x01, 0x01])
    ]
    
    @State var compared: [DiffResult] = compare(
        left: Self.left,
        right: Self.right
    )
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(Array(compared.enumerated()), id: \.offset) {
                    comparisonView(for: $0.element)
                }
            }
        }.onAppear {
            self.compared = compare(left: Self.left, right: Self.right)
        }
    }
    
    @ViewBuilder
    func comparisonView(for diff: DiffResult) -> some View {
        HStack(spacing: commonPadding) {
            Group {
                switch diff {
                case .equal(let lhs, let rhs):
                    equalDiffView(lhs, rhs)
                case .different(let lhs, let rhs):
                    differentDiffView(lhs, rhs)
                case .rightMissing(let lhs):
                    rightMissingDiffView(lhs)
                case .leftMissing(let rhs):
                    leftMissingDiffView(rhs)
                }
            }
        }
    }
    
    @ViewBuilder
    func differentDiffView(_ lhs: EMVTag, _ rhs: EMVTag) -> some View {
        let byteDiffs = compare(left: lhs.value, right: rhs.value)
        
        GroupBox {
            VStack(alignment: .leading) {
                tagTypeView(for: lhs.tag)
                bytesDiffView(results: byteDiffs, isLeft: true)
            }
            
        }
        GroupBox {
            VStack {
                tagTypeView(for: rhs.tag)
                bytesDiffView(results: byteDiffs, isLeft: false)
            }
        }
    }
    
    
    
    @ViewBuilder
    func equalDiffView(_ lhs: EMVTag, _ rhs: EMVTag) -> some View {
        GroupBox {
            Text("\(lhs.tag.hexString)")
                .frame(maxWidth: .infinity)
        }
        GroupBox {
            Text("\(rhs.tag.hexString)")
                .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    func tagTypeView(for tag: UInt64) -> some View {
        Text(tag.hexString)
            .font(.title2.monospaced())
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func byteValueView(for tag: UInt8) -> some View {
        Text(tag.hexString)
            .font(.title3.monospaced())
    }
    
    @ViewBuilder
    func bytesDiffView(results: [ByteDiffResult], isLeft: Bool) -> some View {
        HStack(spacing: 0.0) {
            ForEach(Array(results.enumerated()), id: \.offset) {
                viewFor($0.element, isLeft: isLeft)
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    func rightMissingDiffView(_ lhs: EMVTag) -> some View {
        GroupBox {
            Text("\(lhs.tag.hexString) -> \(lhs.value.map(\.hexString).joined())")
                .frame(maxWidth: .infinity)
        }
        Spacer()
            .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    func leftMissingDiffView(_ rhs: EMVTag) -> some View {
        Spacer()
            .frame(maxWidth: .infinity)
        GroupBox {
            Text("\(rhs.tag.hexString) -> \(rhs.value.map(\.hexString).joined())")
                .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    func viewFor(_ diffResult: ByteDiffResult, isLeft: Bool) -> some View {
        switch diffResult {
        case .equal(let byte):
            byteValueView(for: byte)
        case .different(let lhs, let rhs):
            byteValueView(for: (isLeft ? lhs : rhs))
                .background(Color(.systemBlue).opacity(0.5))
        case .rightMissing(let lhs):
            if isLeft {
                byteValueView(for: lhs)
                    .background(Color.red)
            } else {
                EmptyView()
            }
        case .leftMissing(let rhs):
            if isLeft == false {
                byteValueView(for: rhs)
                    .background(Color.red)
            } else {
                EmptyView()
            }
        }
    }
    
}

func compare(left: [EMVTag], right: [EMVTag]) -> [DiffResult] {
    var leftIdx = left.startIndex
    var rightIdx = right.startIndex
    var results = [DiffResult]()
    
    while leftIdx != left.endIndex || rightIdx != right.endIndex {
        // elements from both are available
        if leftIdx < left.endIndex && rightIdx < right.endIndex {
            let currentL = left[leftIdx]
            let currentR = right[rightIdx]
            
            // tag is the same - check value
            if currentL.tag == currentR.tag {
                // same value
                if currentL.value == currentR.value {
                    results.append(.equal(currentL, currentR))
                // different value
                } else {
                    results.append(.different(currentL, currentR))
                }
                leftIdx += 1
                rightIdx += 1
            // tags are different - append left first
            } else {
                results.append(.rightMissing(currentL))
                leftIdx += 1
            }
        // append the rest of the right
        } else if leftIdx == left.endIndex {
            results.append(
                contentsOf: right.suffix(from: rightIdx).map(DiffResult.leftMissing)
            )
            rightIdx = right.endIndex
        // apend the rest of the left
        } else if rightIdx == right.endIndex {
            results.append(
                contentsOf: left.suffix(from: leftIdx).map(DiffResult.rightMissing)
            )
            leftIdx = left.endIndex
        }
    }
    
    return results
}

func compare(left: [UInt8], right: [UInt8]) -> [ByteDiffResult] {
    var leftIdx = left.startIndex
    var rightIdx = right.startIndex
    var results = [ByteDiffResult]()
    
    while leftIdx != left.endIndex || rightIdx != right.endIndex {
        // elements from both are available
        if leftIdx < left.endIndex && rightIdx < right.endIndex {
            let currentL = left[leftIdx]
            let currentR = right[rightIdx]
            
            // byte is the same
            if currentL == currentR {
                results.append(.equal(currentL))
            // bytes are different
            } else {
                results.append(.different(currentL, currentR))
            }
            
            leftIdx += 1
            rightIdx += 1
            // append the rest of the right
        } else if leftIdx == left.endIndex {
            results.append(
                contentsOf: right.suffix(from: rightIdx).map(ByteDiffResult.leftMissing)
            )
            rightIdx = right.endIndex
            // apend the rest of the left
        } else if rightIdx == right.endIndex {
            results.append(
                contentsOf: left.suffix(from: leftIdx).map(ByteDiffResult.rightMissing)
            )
            leftIdx = left.endIndex
        }
    }
    
    return results
}

enum ByteDiffResult {
    
    case equal(UInt8)
    case different(UInt8, UInt8)
    case rightMissing(UInt8)
    case leftMissing(UInt8)
    
}

enum DiffResult: CustomStringConvertible {
    case equal(EMVTag, EMVTag)
    case different(EMVTag, EMVTag)
    case rightMissing(EMVTag)
    case leftMissing(EMVTag)
    
    var description: String {
        switch self {
        case .equal(let lhs, let rhs):
            return "\(lhs) \(rhs)"
        case .different(let lhs, let rhs):
            return "\(lhs) \(rhs)"
        case .rightMissing(let lhs):
            return "\(lhs)"
        case .leftMissing(let rhs):
            return "\(rhs)"
        }
    }
}

struct DiffView2_Previews: PreviewProvider {
    static var previews: some View {
        DiffView2()
            .frame(width: 400.0)
    }
}

extension EMVTag {
    
    init(bytes: [UInt8]) {
        try! self.init(tlv: .parse(bytes: bytes).first!)
    }
    
}
