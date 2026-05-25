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
    let tagCode: UInt64
    let headerVM: TagHeaderVM
    let valueVM: TagValueVM
    let canExpand: Bool
    let showsDetails: Bool
    let selectedMeanings: [String]
    let isEdited: Bool
    let asciiValue: String?

}

internal struct PlainTagView: View {
    
    @EnvironmentObject private var windowVM: MainVM
    @State internal var isExpanded: Bool = false
    @State private var showsMappingPicker: Bool = false
    @State private var showsAsciiEditor: Bool = false
    @State private var asciiEditText: String = ""

    private let vm: PlainTagVM
    
    internal init(vm: PlainTagVM) {
        self.vm = vm
    }
    
    internal var body: some View {
        HStack(spacing: 0.0) {
            VStack(alignment: .leading, spacing: commonPadding) {
                HStack(spacing: commonPadding) {
                    if vm.isEdited {
                        Circle()
                            .fill(.orange)
                            .frame(width: 6.0, height: 6.0)
                            .transition(.scale.combined(with: .opacity))
                    }
                    TagHeaderView(vm: vm.headerVM)
                }
                .animation(.spring(duration: 0.3), value: vm.isEdited)
                tagValueView
            }.frame(maxWidth: .infinity, alignment: .leading)

            mappingPickerButton
            asciiEditButton

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
    
    @ViewBuilder
    private var mappingPickerButton: some View {
        if let mapping = windowVM.tagParser.tagMapper.mappings[vm.tagCode] {
            let rows = mapping.values
                .sorted(by: { $0.key < $1.key })
                .map { MappingPickerRow(id: $0.key, meaning: $0.value) }
            Button { showsMappingPicker = true } label: {
                GroupBox {
                    Label("Select value", systemImage: "list.bullet")
                        .labelStyle(.iconOnly)
                        .padding(.horizontal, commonPadding)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, commonPadding)
            .mappingPickerPopover(isPresented: $showsMappingPicker, rows: rows) { value in
                windowVM.selectMappingValue(value, for: vm.id)
            }
        }
    }

    @ViewBuilder
    private var asciiEditButton: some View {
        if vm.asciiValue != nil {
            Button { showsAsciiEditor = true } label: {
                GroupBox {
                    Label("Edit value", systemImage: "character.cursor.ibeam")
                        .labelStyle(.iconOnly)
                        .padding(.horizontal, commonPadding)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, commonPadding)
            .popover(isPresented: $showsAsciiEditor) {
                TextField("", text: $asciiEditText)
                    .font(.body.monospaced())
                    .onChange(of: asciiEditText) { _, new in windowVM.setAsciiValue(new, for: vm.id) }
                    .onSubmit { showsAsciiEditor = false }
                    .padding()
                    .frame(minWidth: 200)
                    .onAppear { asciiEditText = vm.asciiValue ?? "" }
            }
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
