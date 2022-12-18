//
//  ConstructedTagView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 01/06/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct ConstructedTagVM: Equatable {
    
    let id: UUID
    let tag: String
    let name: String?
    let headerVM: TagHeaderVM
    let valueVM: TagValueVM
    let subtags: [TagRowVM]
    let showsDetails: Bool
    
}

internal struct ConstructedTagView: View {
    
    @EnvironmentObject private var windowVM: MainVM
    
    internal let vm: ConstructedTagVM
    
    internal var body: some View {
        let binding = windowVM.expandedBinding(for: vm.id)
        
        return HStack {
            VStack(alignment: .leading) {
                disclosureGroup(with: binding)
                if binding.wrappedValue == false {
                    HStack(spacing: 0.0) {
                        TagValueView(vm: vm.valueVM)
                            .multilineTextAlignment(.leading)
                            .padding(.top, -commonPadding)
                    }
                }
            }
            
            if vm.showsDetails && binding.wrappedValue == false {
                DetailsButton(id: vm.id)
            }
        }
        .contentShape(Rectangle())
        .gesture(TapGesture().modifiers(.command).onEnded { _ in
            windowVM.onTagSelected(id: vm.id)
        })
        .onTapGesture {
            binding.wrappedValue.toggle()
        }
    }
    
    private func disclosureGroup(
        with binding: Binding<Bool>
    ) -> some View {
        DisclosureGroup(
            isExpanded: binding,
            content: {
                VStack(alignment: .leading, spacing: commonPadding) {
                    ForEach(vm.subtags, content: TagRowView.init(vm:))
                }
                .padding(.top, commonPadding)
            }, label: {
                TagHeaderView(vm: vm.headerVM)
                    .padding(.leading, commonPadding)
                    .padding(.vertical, -commonPadding)
            }
        )
        .animation(.none, value: binding.wrappedValue)
    }
    
}


struct ConstructedTagView_Previews: PreviewProvider {
    static var previews: some View {
        ConstructedTagView(vm: .make(with: .mockTagConstructed))
            .environmentObject(MainVM())
    }
}
