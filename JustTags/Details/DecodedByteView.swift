//
//  DecodedByteView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 10/10/2022.
//

import SwiftUI
import SwiftyEMVTags

enum DecodedGroupVM: Equatable {
    case rows([DecodedRowVM])
    case picker(EnumGroupPickerVM)
}

struct DecodedByteVM: Equatable {

    internal let title: String
    internal let groups: [DecodedGroupVM]
    internal let idx: Int
    internal let isPlaceholder: Bool

    internal init(idx: Int, name: String?, groups: [DecodedGroupVM], isPlaceholder: Bool = false) {
        let name = name.map { ": \($0)" } ?? ""
        self.title = "Byte \(idx + 1)\(name)"
        self.groups = groups
        self.idx = idx
        self.isPlaceholder = isPlaceholder
    }

}

struct DecodedByteView: View {

    private static let rowHeight = 25.0
    private static let borderColor: Color = Color(nsColor: .tertiaryLabelColor)
    private static let bitHeaderValues = stride(from: UInt8.bitWidth, through: 1, by: -1)
        .map { "b\($0)" }

    @Environment(\.isLibrary) private var isLibrary

    internal let vm: DecodedByteVM

    internal var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: commonPadding) {
                Text(vm.title)
                    .font(.title2)
                ForEach(Array(renderItems.enumerated()), id: \.offset) { _, item in
                    switch item {
                    case .picker(let pickerVM):
                        EnumGroupPickerRow(vm: pickerVM)
                    case .rows(let rows):
                        VStack(spacing: 0.0) {
                            bitHeaderRow
                            ForEach(Array(rows.enumerated()), id: \.offset) {
                                DecodedRowView(vm: $0.element)
                            }
                        }
                        .border(Self.borderColor, width: 1.0)
                    }
                }
            }
            .environment(\.isLibrary, vm.isPlaceholder || isLibrary)
            .environment(\.currentByteIdx, vm.idx)
        }
    }

    private enum RenderItem {
        case picker(EnumGroupPickerVM)
        case rows([DecodedRowVM])
    }

    private var renderItems: [RenderItem] {
        var items: [RenderItem] = []
        var pendingRows: [DecodedRowVM] = []
        for group in vm.groups {
            switch group {
            case .picker(let p):
                if pendingRows.isEmpty == false {
                    items.append(.rows(pendingRows))
                    pendingRows = []
                }
                items.append(.picker(p))
            case .rows(let r):
                pendingRows.append(contentsOf: r)
            }
        }
        if pendingRows.isEmpty == false {
            items.append(.rows(pendingRows))
        }
        return items
    }
    
    private var bitHeaderRow: some View {
        HStack(spacing: 0.0) {
            ForEach(Self.bitHeaderValues, id: \.self) { text in
                bitView(with: text)
                    .font(.body.bold())
            }
            Text("Meaning")
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .frame(height: Self.rowHeight)
                .border(Self.borderColor, width: 0.5)
        }
    }
    
    private func bitView(with text: String?) -> some View {
        Rectangle()
            .foregroundStyle(.clear)
            .border(Self.borderColor, width: 0.5)
            .frame(width: Self.rowHeight, height: Self.rowHeight)
            .overlay {
                text.map(Text.init)
            }
    }

}

struct DecodedByteView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: commonPadding) {
            ForEach(
                Array(EMVTag
                    .mockTag
                    .tagDetailsVMs()
                    .flatMap(\.bytes)
                ),
                id: \.idx,
                content: DecodedByteView.init(vm:)
            )
        }.padding()
    }
}
