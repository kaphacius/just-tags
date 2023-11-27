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
    
    init(tagParser: TagParser) {
        self._vm = .init(wrappedValue: .init(tagParser: tagParser))
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
        .navigationTitle(vm.selectedKernel.name)
        .background(searchButton)
        .focusedSceneValue(\.currentWindow, .library)
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
                ScrollView {
                    VStack(spacing: 0.0) {
                        TagDetailsView(vm: selectedTag.tagDetailsVM)
                            .environment(\.isLibrary, true)
                        if let mapping = vm.tagMappings[selectedTag.info.tag] {
                            TagMappingView(listVMs: mapping.tagMappingListVMs)
                                .padding(.top, -commonPadding)
                        }
                    }
                }
            } else {
                Text("No Tag Selected")
                    .font(.largeTitle)
                    .fontWeight(.light)
                    .foregroundStyle(.tertiary)
            }
        }.frame(minWidth: detailWidth)
    }
    
    private var searchButton: some View {
        Button("Search") {
            searchInProgress.toggle()
        }
        .frame(width: 0.0, height: 0.0)
        .keyboardShortcut("f", modifiers: [.command])
        .hidden()
    }

}

struct LibraryView_Previews: PreviewProvider {
    
    static var previews: some View {
        LibraryView(
            tagParser: TagParser(tagDecoder: AppVM.shared.tagDecoder),
            selectedTagIdx: 220
        ).frame(width: 1000.0)
    }
}
