//
//  MappingPickerPopover.swift
//  JustTags
//

import SwiftUI

struct MappingPickerRow: Identifiable {
    let id: String
    let meaning: String
    let label: String

    init(id: String, meaning: String) {
        self.id = id.uppercased()
        self.meaning = meaning
        self.label = self.id + "  " + meaning
    }
}

extension View {
    func mappingPickerPopover(
        isPresented: Binding<Bool>,
        rows: [MappingPickerRow],
        onSelect: @escaping (String) -> Void
    ) -> some View {
        popover(isPresented: isPresented) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(rows) { row in
                        Button {
                            onSelect(row.id)
                            isPresented.wrappedValue = false
                        } label: {
                            GroupBox {
                                Text(row.label)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 3)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 6)
                        .padding(.trailing, 2)
                        .padding(.vertical, 2)
                    }
                }
            }
            .frame(maxHeight: 300)
            .padding(.vertical, 6)
        }
    }
}
