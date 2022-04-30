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
    let isDiffing: Bool
    
    internal init(diffedTag: DiffedTag) {
        self.tag = diffedTag.tag
        self.byteDiffResults = diffedTag.diff
        self.isDiffing = true
    }
    
    internal init(tag: EMVTag) {
        self.tag = tag
        self.byteDiffResults = []
        self.isDiffing = false
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
    
    @ViewBuilder
    func tagValueView(for tag: EMVTag) -> some View {
        if isDiffing {
            diffedValueView
        } else {
            valueView
        }
    }
    
    @ViewBuilder
    private var valueView: some View {
        Text(tag.value.hexString)
            .font(.title3.monospaced())
    }
    
    @ViewBuilder
    private var diffedValueView: some View {
        HStack(alignment: .top, spacing: 0.0) {
            ForEach(Array(zip(tag.value, byteDiffResults).enumerated()), id: \.offset) { (offset, diffedByte) in
                diffedByteView(diffedByte)
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    func diffedByteView(_ diffedByte: DiffedByte) -> some View {
        switch diffedByte.result {
        case .equal:
            byteValueView(for: diffedByte.byte)
        case .different:
            byteValueView(for: diffedByte.byte)
                .background(diffBackground)
        }
    }
    
    @ViewBuilder
    func byteValueView(for tag: UInt8) -> some View {
        Text(tag.hexString)
            .font(.title3.monospaced())
    }

}

struct TagRowView_Previews: PreviewProvider {
    static var previews: some View {
        TagRowView(tag: .init(hexString: "9F33032808C8"))
        TagRowView(
            diffedTag: (tag: .init(hexString: "9F33032808C8"), diff: [.equal, .different, .different])
        )
    }
}


