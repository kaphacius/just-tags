//
//  TagRowView.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 22/04/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct TagRowView: View {

    private let tag: EMVTag
    private let byteDiffResults: [DiffResult]
    private let isDiffing: Bool
    private let canExpand: Bool
    
    @State private var isExpanded: Bool = false
    
    internal init(diffedTag: DiffedTag) {
        self.tag = diffedTag.tag
        self.byteDiffResults = diffedTag.diff
        self.isDiffing = true
        self.canExpand = diffedTag.tag.decodedMeaningList.isEmpty == false
    }
    
    internal init(tag: EMVTag) {
        self.tag = tag
        self.byteDiffResults = []
        self.isDiffing = false
        self.canExpand = tag.decodedMeaningList.isEmpty == false
    }
    
    internal var body: some View {
        GroupBox {
            primitiveTagView
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private var primitiveTagView: some View {
        VStack(alignment: .leading, spacing: commonPadding) {
            tagHeaderView
            if canExpand {
                expandableValueView
                    .padding(-commonPadding)
            } else {
                tagValueView
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isExpanded.toggle()
        }
    }
    
    private var tagHeaderView: some View {
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
    var tagValueView: some View {
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
    private func diffedByteView(_ diffedByte: DiffedByte) -> some View {
        switch diffedByte.result {
        case .equal:
            byteValueView(for: diffedByte.byte)
        case .different:
            byteValueView(for: diffedByte.byte)
                .background(diffBackground)
        }
    }
    
    @ViewBuilder
    private func byteValueView(for byte: UInt8) -> some View {
        Text(byte.hexString)
            .font(.title3.monospaced())
    }
    
    private var expandableValueView: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                SelectedMeaningList(tag: tag)
                    .padding(.leading, commonPadding * 3)
            }, label: {
                tagValueView
            }
        )
        .padding(.horizontal, commonPadding)
        .animation(.none, value: isExpanded)
    }

}

struct TagRowView_Previews: PreviewProvider {
    static var previews: some View {
        TagRowView(tag: .init(hexString: "9F33032808C8"))
        TagRowView(
            diffedTag: (tag: .init(hexString: "9F33032808C8"), diff: [.equal, .different, .different])
        )
        TagRowView(tag: EMVTag(tlv: mockTLV, info: mockInfo, subtags: []))
    }
}


