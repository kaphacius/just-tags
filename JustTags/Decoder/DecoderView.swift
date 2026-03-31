//
//  DecoderView.swift
//  JustTags
//

import SwiftUI
import SwiftyEMVTags

struct DecoderView: View {

    @StateObject private var vm: DecoderVM
    @State private var searchInProgress: Bool = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    init(tagParser: TagParser) {
        self._vm = .init(wrappedValue: .init(tagParser: tagParser))
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            tagList
                .navigationSplitViewColumnWidth(min: 280.0, ideal: 320.0)
        } detail: {
            decodePanel
        }
        .searchable(text: $vm.searchText, isPresented: $searchInProgress)
        .navigationTitle(WindowType.Case.decoder.title)
        .background(searchButton)
        .focusedSceneValue(\.currentWindow, .decoder)
    }

    // MARK: - Tag list (sidebar)

    @ViewBuilder
    private var tagList: some View {
        ScrollView {
            ForEach(vm.sections) { section in
                LazyVStack {
                    if vm.sections.count > 1 {
                        sectionTitle(section.title)
                    }
                    ForEach(section.items, id: \.self) { tag in
                        tagRow(for: tag)
                    }
                }
            }
        }
        .background(.background)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3.italic())
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, commonPadding * 2)
            .padding(.vertical, commonPadding)
            .background { Rectangle().foregroundStyle(.tertiary) }
    }

    private func tagRow(for tag: TagDecodingInfo) -> some View {
        GroupBox {
            HStack {
                Text(tag.info.tag.hexString)
                    .font(.title2.monospaced())
                Text(tag.info.name)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4.0, style: .continuous)
                .strokeBorder(lineWidth: 1.0, antialiased: true)
                .foregroundColor(vm.selectedTag == tag ? .secondary : .clear)
                .animation(.easeOut(duration: 0.25), value: vm.selectedTag)
        )
        .onTapGesture {
            vm.selectedTag = vm.selectedTag == tag ? nil : tag
        }
        .padding(.horizontal, commonPadding * 2)
    }

    // MARK: - Decode panel (detail)

    @ViewBuilder
    private var decodePanel: some View {
        if let selectedTag = vm.selectedTag {
            VStack(spacing: 0.0) {
                inputField(for: selectedTag)
                    .padding(commonPadding)
                Divider()
                decodeResult(for: selectedTag)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            Text("Select a tag to decode")
                .font(.largeTitle)
                .fontWeight(.light)
                .foregroundStyle(.tertiary)
        }
    }

    private func inputField(for tag: TagDecodingInfo) -> some View {
        TextField(inputPlaceholder(for: tag), text: $vm.inputString)
            .font(.body.monospaced())
            .textFieldStyle(.roundedBorder)
    }

    private func inputPlaceholder(for tag: TagDecodingInfo) -> String {
        let exactCount = tag.bytes.count
        if exactCount > 0 {
            return "Enter \(exactCount) \(exactCount == 1 ? "byte" : "bytes") as hex or base64"
        }
        let min = tag.info.minLength
        let max = tag.info.maxLength
        if let minInt = Int(min), let maxInt = Int(max) {
            if minInt == maxInt {
                return "Enter \(minInt) \(minInt == 1 ? "byte" : "bytes") as hex or base64"
            } else {
                return "Enter \(minInt)–\(maxInt) bytes as hex or base64"
            }
        }
        return "Enter hex or base64 value"
    }

    @ViewBuilder
    private func decodeResult(for tag: TagDecodingInfo) -> some View {
        if vm.tagDetailVMs.isEmpty {
            Text("Unable to decode the given value")
                .font(.title2)
                .fontWeight(.light)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.tagDetailVMs.count == 1, let first = vm.tagDetailVMs.first {
            ScrollView {
                TagDetailsView(vm: first)
            }
        } else {
            TabView {
                ForEach(vm.tagDetailVMs, id: \.kernel) { detailVM in
                    ScrollView {
                        TagDetailsView(vm: detailVM)
                    }
                    .tabItem { Text(detailVM.kernel) }
                }
            }
        }
    }

    private var searchButton: some View {
        Button("Search") { searchInProgress.toggle() }
            .frame(width: 0.0, height: 0.0)
            .keyboardShortcut("f", modifiers: [.command])
            .hidden()
    }

}
