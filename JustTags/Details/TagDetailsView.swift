//
//  EMVTagDetailView.swift
//  BERTLVEMV
//
//  Created by Yurii Zadoianchuk on 09/03/2022.
//

import SwiftUI
import SwiftyEMVTags

struct TagMappingVM {
    let rowVMs: [(value: String, meaning: String)]
    let currentValue: String
    let selectHandler: (String) -> Void
}

struct TagAsciiVM {
    let currentValue: String
    let editHandler: (String) -> Void
}

struct TagDetailsVM {

    let tag: String
    let name: String
    let info: TagInfoVM
    let bytes: [DecodedByteVM]
    let kernel: String
    let mapping: TagMappingVM?
    let ascii: TagAsciiVM?

    init(
        tag: String,
        name: String,
        info: TagInfoVM,
        bytes: [DecodedByteVM],
        kernel: String,
        mapping: TagMappingVM? = nil,
        ascii: TagAsciiVM? = nil
    ) {
        self.tag = tag
        self.name = name
        self.info = info
        self.bytes = bytes
        self.kernel = kernel
        self.mapping = mapping
        self.ascii = ascii
    }

}

struct TagDetailsView: View {

    internal let vm: TagDetailsVM

    @State var infoOpen = true
    @State private var asciiEditText: String

    init(vm: TagDetailsVM) {
        self.vm = vm
        _asciiEditText = State(initialValue: vm.ascii?.currentValue ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: commonPadding) {
            header
            info
            bytes
            if let asciiVM = vm.ascii {
                asciiEditor(asciiVM: asciiVM)
            }
            if let mapping = vm.mapping {
                mappingDropdown(mapping: mapping)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(commonPadding)
        .onChange(of: vm.ascii?.currentValue) { _, newValue in
            let new = newValue ?? ""
            if new != asciiEditText {
                asciiEditText = new
            }
        }
    }

    private var header: some View {
        GroupBox {
            VStack(spacing: 0.0) {
                Text(vm.tag).font(.largeTitle.monospaced())
                Text(vm.name).font(.title2)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var info: some View {
        GroupBox {
            DisclosureGroup(
                isExpanded: $infoOpen,
                content: {
                    HStack(spacing: 0.0) {
                        TagInfoView(vm: vm.info)
                        Spacer()
                    }
                }, label: {
                    Label("Tag Info", systemImage: "info.circle.fill")
                        .font(.headline)
                }
            ).padding(.leading, commonPadding)
        }
        .onTapGesture { infoOpen.toggle() }
    }

    private var bytes: some View {
        ForEach(vm.bytes, id: \.idx, content: DecodedByteView.init(vm:))
    }

    private func asciiEditor(asciiVM: TagAsciiVM) -> some View {
        GroupBox {
            TextField("", text: $asciiEditText)
                .font(.title3.monospaced())
                .onChange(of: asciiEditText) { _, newValue in asciiVM.editHandler(newValue) }
        }
    }

    private func mappingDropdown(mapping: TagMappingVM) -> some View {
        GroupBox {
            Menu {
                ForEach(mapping.rowVMs, id: \.value) { rowVM in
                    Button(rowVM.value + "  " + rowVM.meaning) {
                        mapping.selectHandler(rowVM.value)
                    }
                }
            } label: {
                HStack {
                    Text(mapping.currentValue)
                        .font(.title3.monospaced())
                    if let current = mapping.rowVMs.first(where: { $0.value.uppercased() == mapping.currentValue.uppercased() }) {
                        Text(current.meaning)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .padding(2)
                .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
    }
}


struct EMVTagDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TagDetailsView(vm: EMVTag.mockTag.tagDetailsVMs.first!)
            .frame(width: detailWidth, height: 1000)
    }
}
