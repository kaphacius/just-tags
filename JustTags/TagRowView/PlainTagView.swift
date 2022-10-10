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
        VStack(alignment: .leading, spacing: commonPadding) {
            TagHeaderView(vm: vm.headerVM)
            tagValueView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .trailing) {
            if vm.showsDetails {
                detailsButton
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
    
    @ViewBuilder
    private func byteValueView(for byte: UInt8) -> some View {
        Text(byte.hexString)
            .font(.title3.monospaced())
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
    
    private var detailsButton: some View {
        Button(
            action: {
                windowVM.onDetailTagSelected(id: vm.id)
            }, label: {
                GroupBox {
                    Label("Details", systemImage: buttonImage)
                    .labelStyle(.iconOnly)
                    .padding(.horizontal, commonPadding)
                }
            }
        )
        .padding(.horizontal, commonPadding)
        .buttonStyle(.plain)
    }
    
    private var buttonImage: String {
        windowVM.detailTag?.id == vm.id ? "lessthan" : "greaterthan"
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
