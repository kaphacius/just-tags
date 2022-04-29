//
//  TagRowView.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 22/04/2022.
//

import SwiftUI
import SwiftyEMVTags

struct TagRowView: View {

    let tag: EMVTag
    let byteDiffResults: [DiffResult]
    
    internal init(tag: EMVTag, byteDiffResults: [DiffResult] = []) {
        self.tag = tag
        self.byteDiffResults = byteDiffResults
    }
    
    var body: some View {
        GroupBox {
            primitiveTagView
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    var primitiveTagView: some View {
        VStack(alignment: .leading, spacing: commonPadding) {
                tagHeaderView(for: tag)
                tagValueView(for: tag)
                    .padding(.vertical, commonPadding)
            }
        .contentShape(Rectangle())
    }
    
    func tagHeaderView(for tag: EMVTag) -> some View {
        HStack {
            Text(tag.tag.hexString)
                .font(.body.monospaced())
                .fontWeight(.semibold)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(tag.name)
                .font(.body)
                .fontWeight(.semibold)
                .minimumScaleFactor(0.5)
        }
    }
    
    func tagValueView(for tag: EMVTag) -> some View {
//        Text(tag.value.map(\.hexString).joined())
//            .font(.body.monospaced()).fontWeight(.light)
//            .frame(alignment: .leading)
        bytesDiffView(bytes: tag.value, results: byteDiffResults)
    }
    
    @ViewBuilder
    func bytesDiffView(bytes: [UInt8], results: [DiffResult]) -> some View {
        HStack(alignment: .top, spacing: 0.0) {
            ForEach(Array(results.enumerated()), id: \.offset) {
                viewFor(results[$0.offset], byte: bytes[$0.offset])
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    func viewFor(_ diffResult: DiffResult, byte: UInt8) -> some View {
        switch diffResult {
        case .equal:
            byteValueView(for: byte)
        case .different:
            byteValueView(for: byte)
                .background(Color.yellow.opacity(0.2))
        }
    }
    
    @ViewBuilder
    func byteValueView(for tag: UInt8) -> some View {
        Text(tag.hexString)
            .font(.title3.monospaced())
    }
    
//    @ViewBuilder
//    func viewFor(_ diffResult: ByteDiffResult, isLeft: Bool) -> some View {
//        switch diffResult {
//        case .equal(let byte):
//            byteValueView(for: byte)
//        case .different(let lhs, let rhs):
//            byteValueView(for: (isLeft ? lhs : rhs))
//                .background(Color(.systemBlue).opacity(0.5))
//        case .rightMissing(let lhs):
//            if isLeft {
//                byteValueView(for: lhs)
//                    .background(Color.red)
//            } else {
//                EmptyView()
//            }
//        case .leftMissing(let rhs):
//            if isLeft == false {
//                byteValueView(for: rhs)
//                    .background(Color.red)
//            } else {
//                EmptyView()
//            }
//        }
//    }
}

struct TagRowView_Previews: PreviewProvider {
    static var previews: some View {
        TagRowView(tag: .init(hexString: "9F33032808C8"))
    }
}


