//
//  AddTagView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/05/2026.
//

import SwiftUI
import SwiftyEMVTags

private struct TagSuggestion: Identifiable {
    let id: String  // uppercase hex tag code
    let name: String
}

private struct SuggestionRow: View {

    let suggestion: TagSuggestion
    let onSelect: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: commonPadding * 2) {
                Text(suggestion.id)
                    .font(.body.monospaced())
                    .frame(minWidth: 44, alignment: .leading)
                Text(suggestion.name)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, commonPadding * 2)
            .padding(.vertical, commonPadding + 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isHovered ? Color(nsColor: .selectedContentBackgroundColor) : .clear)
            .foregroundStyle(isHovered ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

}

internal struct AddTagView: View {

    @EnvironmentObject private var windowVM: MainVM

    private let title: String
    private let onAdd: (String, String) -> Void

    @State private var tagHex: String = ""
    @State private var valueHex: String = ""
    @FocusState private var focusedField: Field?

    private enum Field { case tag, value }

    internal init(title: String = "Add Tag", onAdd: @escaping (String, String) -> Void) {
        self.title = title
        self.onAdd = onAdd
    }

    internal var body: some View {
        VStack(alignment: .leading, spacing: commonPadding * 2) {
            Text(title).font(.headline)

            VStack(alignment: .leading, spacing: commonPadding) {
                Text("Tag").font(.caption).foregroundStyle(.secondary)
                TextField("e.g. 9F33", text: $tagHex)
                    .font(.body.monospaced())
                    .focused($focusedField, equals: .tag)
                    .onSubmit { focusedField = .value }
                if suggestions.isEmpty == false {
                    suggestionsView
                }
            }

            VStack(alignment: .leading, spacing: commonPadding) {
                Text("Value").font(.caption).foregroundStyle(.secondary)
                TextField("Hex", text: $valueHex)
                    .font(.body.monospaced())
                    .focused($focusedField, equals: .value)
                    .onSubmit {
                        if canAdd { performAdd() }
                    }
                if let count = expectedByteCount {
                    Text("\(count) \(count == 1 ? "byte" : "bytes") expected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if isDuplicate {
                Text("Tag already exists in the list")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }

            Button("Add", action: performAdd)
                .disabled(canAdd == false)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(commonPadding * 2)
        .frame(minWidth: 280)
        .onAppear { focusedField = .tag }
    }

    private var suggestionsView: some View {
        List(suggestions) { suggestion in
            SuggestionRow(suggestion: suggestion) {
                tagHex = suggestion.id
                focusedField = .value
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparatorTint(Color(nsColor: .separatorColor))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(height: min(CGFloat(suggestions.count), 6) * 28)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color(nsColor: .separatorColor))
        )
    }

    private var suggestions: [TagSuggestion] {
        guard tagHex.count >= 1 else { return [] }
        let normalized = tagHex.lowercased()
        var seen = Set<String>()
        return Array(
            windowVM.tagParser.initialKernels
                .flatMap(\.tags)
                .compactMap { info -> TagSuggestion? in
                    let hex = info.info.tag.hexString.uppercased()
                    let name = info.info.name
                    guard hex.lowercased().hasPrefix(normalized)
                        || hex.lowercased().contains(normalized)
                        || name.lowercased().contains(normalized) else { return nil }
                    guard seen.insert(hex).inserted else { return nil }
                    return TagSuggestion(id: hex, name: name)
                }
                .prefix(20)
        )
    }

    private var expectedByteCount: Int? {
        guard tagHex.count > 0, tagHex.count.isMultiple(of: 2),
              let tagBytes = [UInt8](hexString: tagHex),
              tagBytes.isEmpty == false else { return nil }
        let tagCode = tagBytes.reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        return windowVM.tagParser.initialKernels
            .flatMap(\.tags)
            .first { $0.info.tag == tagCode && $0.bytes.count > 0 }
            .map(\.bytes.count)
    }

    private var canAdd: Bool {
        tagHex.count > 0 && tagHex.count.isMultiple(of: 2)
            && [UInt8](hexString: tagHex) != nil
            && valueHex.count > 0
            && [UInt8](hexString: valueHex) != nil
    }

    private var isDuplicate: Bool {
        guard tagHex.count > 0, tagHex.count.isMultiple(of: 2),
              let tagBytes = [UInt8](hexString: tagHex),
              tagBytes.isEmpty == false else { return false }
        let tagCode = tagBytes.reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        return windowVM.initialTags.contains { $0.tag.tag == tagCode }
    }

    private func performAdd() {
        onAdd(tagHex.uppercased(), valueHex.uppercased())
    }

}
