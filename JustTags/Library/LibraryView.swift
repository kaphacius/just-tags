//
//  LibraryView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 30/12/2022.
//

import SwiftUI
import SwiftyEMVTags
import Combine

struct LibraryView: View {

    @StateObject private var vm: LibraryVM

    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var searchInProgress: Bool = false
    @FocusState private var byteInputFocused: Bool
    @FocusState private var searchFieldFocused: Bool

    init(tagParser: TagParser, initialState: LibraryWindowState? = nil) {
        self._vm = .init(wrappedValue: .init(tagParser: tagParser, initialState: initialState))
    }

    // This is for previews
    init(tagParser: TagParser, selectedTagIdx: Int) {
        self._vm = .init(
            wrappedValue: .init(tagParser: tagParser, selectedTagIdx: selectedTagIdx)
        )
    }

    internal var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            sidebar: sidebar,
            content: content,
            detail: detail
        )
        .searchable(text: $vm.searchText, isPresented: $searchInProgress)
        .searchFocusedIfAvailable($searchFieldFocused)
        .background(searchButton)
        .focusedSceneValue(\.currentWindow, .library)
        .onChange(of: vm.autoSelectCount) { _, _ in byteInputFocused = true }
    }

    @ViewBuilder
    private func sidebar() -> some View {
        List(vm.kernels, id: \.self, selection: $vm.selectedKernel) { kernel in
            NavigationLink(value: kernel) {
                Text(kernel.id)
            }.tag(kernel)
        }
        .navigationSplitViewColumnWidth(150.0)
    }

    @ViewBuilder
    private func content() -> some View {
        LibraryKernelInfoView(
            selectedTag: $vm.selectedTag,
            sections: vm.tagListSections
        )
        .navigationSplitViewColumnWidth(min: detailWidth, ideal: detailWidth)
    }

    @ViewBuilder
    private func detail() -> some View {
        Group {
            if let selectedTag = vm.selectedTag {
                VStack(spacing: 0.0) {
                    if vm.isDecodable(selectedTag) {
                        inputField(for: selectedTag)
                            .padding(commonPadding)
                        Divider()
                    }
                    if vm.tagDetailVMs.isEmpty {
                        ScrollView {
                            VStack(spacing: 0.0) {
                                TagDetailsView(vm: selectedTag.tagDetailsVM)
                                    .environment(\.isLibrary, true)
                                if let mapping = vm.tagMappings[selectedTag.info.tag],
                                   mapping.kernel == selectedTag.info.kernel {
                                    TagMappingView(listVMs: mapping.tagMappingListVMs)
                                        .padding(.top, -commonPadding)
                                }
                            }
                        }
                    } else if vm.tagDetailVMs.count == 1, let first = vm.tagDetailVMs.first {
                        ScrollView {
                            TagDetailsView(vm: first)
                        }
                        .environment(\.bitToggleHandler, vm.toggleBit)
                    } else {
                        TabView {
                            ForEach(vm.tagDetailVMs, id: \.kernel) { detailVM in
                                ScrollView {
                                    TagDetailsView(vm: detailVM)
                                }
                                .tabItem { Text(detailVM.kernel) }
                            }
                        }
                        .environment(\.bitToggleHandler, vm.toggleBit)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                Text("No Tag Selected")
                    .font(.largeTitle)
                    .fontWeight(.light)
                    .foregroundStyle(.tertiary)
            }
        }.frame(minWidth: detailWidth)
    }

    private func inputField(for tag: TagDecodingInfo) -> some View {
        TextField(inputPlaceholder(for: tag), text: $vm.inputString)
            .font(.body.monospaced())
            .textFieldStyle(.roundedBorder)
            .focused($byteInputFocused)
            .onKeyPress(.escape) {
                DispatchQueue.main.async {
                    vm.selectedTag = nil
                    searchFieldFocused = true
                }
                return .handled
            }
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

    private var searchButton: some View {
        Group {
            Button("Search") { searchInProgress.toggle() }
                .keyboardShortcut("f", modifiers: [.command])
            Button("Previous tag") { vm.selectPrevious() }
                .keyboardShortcut(.upArrow, modifiers: [])
                .disabled(byteInputFocused)
            Button("Next tag") { vm.selectNext() }
                .keyboardShortcut(.downArrow, modifiers: [])
                .disabled(byteInputFocused)
        }
        .frame(width: 0.0, height: 0.0)
        .hidden()
    }

}

private extension View {
    @ViewBuilder
    func searchFocusedIfAvailable(_ binding: FocusState<Bool>.Binding) -> some View {
        if #available(macOS 15.0, *) {
            self.searchFocused(binding)
        } else {
            self
        }
    }
}

struct LibraryView_Previews: PreviewProvider {

    static var previews: some View {
        LibraryView(
            tagParser: TagParser(tagDecoder: AppVM.shared.tagDecoder!),
            selectedTagIdx: 220
        ).frame(width: 1000.0)
    }
}
