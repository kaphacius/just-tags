//
//  ConstructedTagView.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 01/06/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct ConstructedTagView: View {
    
    @EnvironmentObject private var windowVM: WindowVM
    
    @State var isExpanded: Bool = false
    
    internal let tag: EMVTag
    
    internal var body: some View {
        return VStack(alignment: .leading) {
            disclosureGroup(for: tag, binding: $isExpanded)
            if isExpanded == false {
                HStack(spacing: 0.0) {
                    TagValueView(tag: tag)
                        .multilineTextAlignment(.leading)
                        .padding(.top, -commonPadding)
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(TapGesture().modifiers(.command).onEnded { _ in
            windowVM.onTagSelected(tag: tag)
        })
        .onTapGesture {
            isExpanded.toggle()
        }
    }
    
    private func disclosureGroup(for tag: EMVTag, binding: Binding<Bool>) -> some View {
        DisclosureGroup(
            isExpanded: binding,
            content: {
                VStack(alignment: .leading, spacing: commonPadding) {
                    ForEach(tag.subtags, content: TagRowView.init(tag:))
                }
                .padding(.top, commonPadding)
            }, label: {
                TagHeaderView(tag: tag)
                    .padding(.leading, commonPadding)
                    .padding(.vertical, -commonPadding)
            }
        )
        .animation(.none, value: binding.wrappedValue)
    }
    
    @ViewBuilder
    private func constructedTagValueView(for tag: EMVTag, binding: Binding<Bool>) -> some View {
        if binding.wrappedValue == false {
            HStack(spacing: 0.0) {
                TagValueView(tag: tag)
                    .multilineTextAlignment(.leading)
                    .padding(.top, -commonPadding)
            }
        }
    }
    
}

#if DEBUG
struct ConstructedTagView_Previews: PreviewProvider {
    static var previews: some View {
        ConstructedTagView(tag: mockTag)
    }
}
#endif
