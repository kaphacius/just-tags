//
//  PrimitiveTagView.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 01/06/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct PrimitiveTagView: View {
    
    @EnvironmentObject private var windowVM: WindowVM
    @State internal var isExpanded: Bool = false
    
    internal let tag: EMVTag
    internal let byteDiffResults: [DiffResult]
    internal let isDiffing: Bool
    internal let canExpand: Bool
    internal let showsDetails: Bool
    
    internal var body: some View {
        VStack(alignment: .leading, spacing: commonPadding) {
            if showsDetails {
                Button(
                    action: { windowVM.selectedTag = tag },
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .gesture(TapGesture().modifiers(.command).onEnded { _ in
            windowVM.onTagSelected(tag: tag)
        })
        .onTapGesture {
            isExpanded.toggle()
        }
    }
    
    @ViewBuilder
    private var tagValueView: some View {
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
}

struct PrimitiveTagView_Previews: PreviewProvider {
    static var previews: some View {
        PrimitiveTagView(
            tag: mockTag,
            byteDiffResults: [],
            isDiffing: false,
            canExpand: false,
            showsDetails: false
        )
    }
}
