//
//  EnumGroupPickerRow.swift
//  JustTags
//

import SwiftUI

struct EnumGroupPickerVM: Equatable {

    internal let name: String
    internal let fullBits: String
    internal let highlightRange: Range<Int>
    internal let currentMeaning: String
    internal let rows: [MappingPickerRow]
    internal let startIndex: Int
    internal let width: Int
    internal let isInteractive: Bool

}

internal struct EnumGroupPickerRow: View {

    @Environment(\.isLibrary) private var isLibrary
    @Environment(\.groupValueHandler) private var groupValueHandler
    @Environment(\.currentByteIdx) private var currentByteIdx

    @State private var showsPicker = false

    internal let vm: EnumGroupPickerVM

    private var isEnabled: Bool {
        vm.isInteractive && isLibrary == false && groupValueHandler != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(vm.name)
                .font(.body.bold())
            GroupBox {
                if vm.isInteractive {
                    Button {
                        showsPicker = true
                    } label: {
                        rowContent(showsChevron: isEnabled)
                    }
                    .buttonStyle(.plain)
                    .disabled(isEnabled == false)
                    .frame(maxWidth: .infinity)
                    .mappingPickerPopover(isPresented: $showsPicker, rows: vm.rows) { id in
                        guard let value = UInt8(id, radix: 2) else { return }
                        groupValueHandler?(currentByteIdx, vm.startIndex, vm.width, value)
                    }
                } else {
                    rowContent(showsChevron: false)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func rowContent(showsChevron: Bool) -> some View {
        HStack {
            bitsView
            if vm.currentMeaning.isEmpty == false {
                Text(vm.currentMeaning)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .padding(2)
    }

    private var bitsView: some View {
        HStack(spacing: 0) {
            ForEach(Array(vm.fullBits.enumerated()), id: \.offset) { idx, char in
                let isHighlighted = vm.highlightRange.contains(idx)
                Text(String(char))
                    .font(.title3.monospaced())
                    .fontWeight(isHighlighted ? .bold : .regular)
                    .foregroundStyle(isHighlighted ? .primary : .tertiary)
            }
        }
    }

}
