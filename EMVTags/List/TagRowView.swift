//
//  TagRowView.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 22/04/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct TagRowView: View {
    
    @Environment (\.selectedTag) private var selectedTag

    private let tag: EMVTag
    private let byteDiffResults: [DiffResult]
    private let isDiffing: Bool
    private let canExpand: Bool
    private let showsDetails: Bool
    
    @State private var isExpanded: Bool = false
    
    internal init(diffedTag: DiffedTag) {
        self.tag = diffedTag.tag
        self.byteDiffResults = diffedTag.diff
        self.isDiffing = true
        self.canExpand = diffedTag.tag.decodedMeaningList.isEmpty == false
        self.showsDetails = canExpand
    }
    
    internal init(tag: EMVTag) {
        self.tag = tag
        self.byteDiffResults = []
        self.isDiffing = false
        self.canExpand = tag.decodedMeaningList.isEmpty == false
        self.showsDetails = canExpand
    }
    
    internal var body: some View {
        GroupBox {
            primitiveTagView
                .frame(maxWidth: .infinity, alignment: .leading)
        }.contextMenu { contextMenu }
    }
    
    @ViewBuilder
    private var primitiveTagView: some View {
        VStack(alignment: .leading, spacing: commonPadding) {
            if showsDetails {
                Button(
                    action: { selectedTag.wrappedValue = tag },
                    label: { TagHeaderView(tag: tag) }
                )
            } else {
                TagHeaderView(tag: tag)
            }
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
    
    @ViewBuilder
    var tagValueView: some View {
        if isDiffing {
            diffedValueView
        } else {
            TagValueView(value: tag.value)
        }
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
    
    @ViewBuilder
    private var contextMenu: some View {
        Button("Copy full tag") {
            NSPasteboard.general.declareTypes([.string], owner: nil)
            NSPasteboard.general.setString(tag.hexString, forType: .string)
        }
        Button("Copy value") {
            NSPasteboard.general.declareTypes([.string], owner: nil)
            NSPasteboard.general.setString(tag.value.hexString, forType: .string)
        }
    }

}

internal struct TagValueView: View {
    internal let value: [UInt8]
    
    internal var body: some View {
        Text(value.hexString)
            .font(.title3.monospaced())
    }
}

internal struct TagHeaderView: View {
    internal let tag: EMVTag
    
    internal var body: some View {
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
}

struct TagRowView_Previews: PreviewProvider {
    static var previews: some View {
        TagRowView(tag: .init(hexString: "e181c7df810c01029f060aa0000000041010d076129f150260519f160f3130303920202020202020202020209f1a0205289f1c0832313930303031389f090200029f3501229f40056000b0a003df812005fc50bca000df8121050010000000df812205fc50bcf8009f1d009f6d02ffffdf81170120df81180120df81190108df811b01b0df811e0110df811f0108df812306000000002500df812406000009999999df812506000009999999df8126060000000050009f530152df811c020078df811d0102df812c0100"))
        TagRowView(
            diffedTag: (tag: .init(hexString: "9F33032808C8"), diff: [.equal, .different, .different])
        )
        TagRowView(tag: EMVTag(tlv: mockTLV, info: mockInfo, subtags: []))
    }
}


