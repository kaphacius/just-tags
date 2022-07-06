//
//  PrimitiveTagView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 01/06/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct PrimitiveTagView: View {
    
    @EnvironmentObject private var windowVM: AnyWindowVM
    @State internal var isExpanded: Bool = false
    
    internal let tag: EMVTag
    internal let byteDiffResults: [DiffResult]
    internal let isDiffing: Bool
    internal let canExpand: Bool
    internal let showsDetails: Bool
    
    internal var body: some View {
        VStack(alignment: .leading, spacing: commonPadding) {
            TagHeaderView(tag: tag)
            if canExpand {
                expandableValueView
                    .padding(-commonPadding)
            } else {
                tagValueView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .trailing) { detailsButton }
        .contentShape(Rectangle())
        .gesture(TapGesture().modifiers(.command).onEnded { _ in
            windowVM.onTagSelected(tag: tag)
        })
        .onTapGesture(count: 2) {
            windowVM.onDetailTagSelected(tag: tag)
        }
        .onTapGesture {
            isExpanded.toggle()
        }
    }
    
    @ViewBuilder
    private var tagValueView: some View {
        if isDiffing {
            DiffedTagValueView(diffedTag: .init(tag: tag, results: byteDiffResults))
        } else {
            TagValueView(tag: tag)
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
    
    private var detailsButton: some View {
        Button(
            action: {
                windowVM.onDetailTagSelected(tag: tag)
            }, label: {
                GroupBox {
                    Label(
                        "Details",
                        systemImage: windowVM.detailTag == tag ? "lessthan" : "greaterthan"
                    )
                    .labelStyle(.iconOnly)
                    .padding(.horizontal, commonPadding)
                }
            }
        )
        .padding(.horizontal, commonPadding)
        .buttonStyle(.plain)
    }
}

private struct DiffedTagValueView: View {
    
    internal let diffedTag: DiffedTag
    
    internal var body: some View {
        Text(text)
            .font(.title3.monospaced())
    }
    
    private let backgroundColorContainer: AttributeContainer = {
        var container = AttributeContainer()
        container.backgroundColor = diffBackground
        return container
    }()
    
    private var text: AttributedString {
        diffedTag.diffedBytes
            .map { diffedByte in
                AttributedString(
                    diffedByte.byte.hexString,
                    attributes: diffedByte.result == .different ? backgroundColorContainer : .init()
                )
            }.reduce(into: AttributedString()) { $0.append($1) }
    }
    
}

#if DEBUG
struct PrimitiveTagView_Previews: PreviewProvider {
    static var previews: some View {
        PrimitiveTagView(
            tag: mockTag,
            byteDiffResults: [],
            isDiffing: false,
            canExpand: false,
            showsDetails: false
        ).environmentObject(MainWindowVM() as AnyWindowVM)
    }
}
#endif
