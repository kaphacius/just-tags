//
//  PrimitiveTagView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 01/06/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct PrimitiveTagView: View {
    
    @EnvironmentObject private var windowVM: MainVM
    @State internal var isExpanded: Bool = false
    
    internal let tag: EMVTag
    internal let canExpand: Bool
    internal let showsDetails: Bool
    
    internal var body: some View {
        VStack(alignment: .leading, spacing: commonPadding) {
            TagHeaderView(tag: tag)
            tagValueView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .trailing) {
            if showsDetails {
                detailsButton
            }
        }
        .contentShape(Rectangle())
        .gesture(TapGesture().modifiers(.command).onEnded { _ in
            windowVM.onTagSelected(id: tag.id)
        })
        .onTapGesture(count: 2) {
            if showsDetails { windowVM.onDetailTagSelected(id: tag.id) }
        }
        .onTapGesture {
            if canExpand { isExpanded.toggle() }
        }
    }
    
    @ViewBuilder
    private var tagValueView: some View {
        if canExpand {
            expandableValueView
                .padding(-commonPadding)
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
                TagValueView(tag: tag)
            }
        )
        .padding(.horizontal, commonPadding)
        .animation(.none, value: isExpanded)
    }
    
    private var detailsButton: some View {
        Button(
            action: {
                windowVM.onDetailTagSelected(id: tag.id)
            }, label: {
                EmptyView()
//                GroupBox {
//                    Label(
//                        "Details",
//                        systemImage: windowVM.detailTag == tag ? "lessthan" : "greaterthan"
//                    )
//                    .labelStyle(.iconOnly)
//                    .padding(.horizontal, commonPadding)
//                }
            }
        )
        .padding(.horizontal, commonPadding)
        .buttonStyle(.plain)
    }
}

//let mockShortTag: EMVTag = .init(hexString: "9F33032808C8")

//struct PrimitiveTagView_Previews: PreviewProvider {
//    static var previews: some View {
//        PrimitiveTagView(
//            tag: mockShortTag,
//            canExpand: false,
//            showsDetails: false
//        ).environmentObject(MainVM())
//    }
//}
