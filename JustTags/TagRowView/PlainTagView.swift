//
//  PlainTagVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 01/06/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct PlainTagVM: Identifiable, Equatable {
    
    typealias ID = EMVTag.ID
    
    let id: UUID
    let headerVM: TagHeaderVM
    let valueVM: TagValueVM
    let canExpand: Bool
    let showsDetails: Bool
    let selectedMeanings: [String]
    
}

internal struct PlainTagView: View {
    
    @EnvironmentObject private var windowVM: MainVM
    @State internal var isExpanded: Bool = false
    
    private let vm: PlainTagVM
    
    internal init(vm: PlainTagVM) {
        self.vm = vm
    }
    
    internal var body: some View {
        HStack(spacing: 0.0) {
            VStack(alignment: .leading, spacing: commonPadding) {
                TagHeaderView(vm: vm.headerVM)
                tagValueView
            }.frame(maxWidth: .infinity, alignment: .leading)
            
            if vm.showsDetails {
                DetailsButton(id: vm.id)
            }
        }
        .contentShape(Rectangle())
        .gesture(TapGesture().modifiers(.command).onEnded { _ in
            windowVM.onTagSelected(id: vm.id)
        })
        .onTapGesture {
            if vm.canExpand { isExpanded.toggle() }
        }
    }
    
    @ViewBuilder
    private var tagValueView: some View {
        if vm.canExpand {
            expandableValueView
                .padding(-commonPadding)
        } else {
            TagValueView(vm: vm.valueVM)
        }
    }
    
    private var expandableValueView: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                SelectedMeaningList(meanings: vm.selectedMeanings)
                    .padding(.leading, commonPadding * 3)
            }, label: {
                TagValueView(vm: vm.valueVM)
            }
        )
        .padding(.horizontal, commonPadding)
        .animation(.none, value: isExpanded)
    }
}

struct PlainTagView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PlainTagView(
                vm: .make(with: .mockTag)
            )
            PlainTagView(
                vm: .make(with: .mockTagExtended)
            )
            PlainTagView(
                vm: .make(with: .mockTag, canExpand: true)
            )
            PlainTagView(
                vm: .make(with: .mockTag, showsDetails: false)
            )
        }.environmentObject(MainVM())
    }
}
