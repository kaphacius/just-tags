//
//  ConstructedTagView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 01/06/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct ConstructedTagView: View {
    
    @EnvironmentObject private var vm: AnyWindowVM
    
    internal let tag: EMVTag
    
    internal var body: some View {
        let binding = vm.binding(for: tag.id)
        
        return VStack(alignment: .leading) {
            disclosureGroup(for: tag, binding: binding)
            if binding.wrappedValue == false {
                HStack(spacing: 0.0) {
                    TagValueView(tag: tag)
                        .multilineTextAlignment(.leading)
                        .padding(.top, -commonPadding)
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(TapGesture().modifiers(.command).onEnded { _ in
            vm.onTagSelected(tag: tag)
        })
        .onTapGesture {
            binding.wrappedValue.toggle()
        }
    }
    
    private func disclosureGroup(
        for tag: EMVTag,
        binding: Binding<Bool>
    ) -> some View {
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
    
}

#if DEBUG
struct ConstructedTagView_Previews: PreviewProvider {
    static var previews: some View {
        ConstructedTagView(tag: mockTag)
            .environmentObject(MainVM() as AnyWindowVM)
    }
}
#endif
