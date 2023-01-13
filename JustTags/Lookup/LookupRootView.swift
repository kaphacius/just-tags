//
//  LookupRootView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 30/12/2022.
//

import SwiftUI
import SwiftyEMVTags
import Combine

struct LookupRootView: View {
    
    @ObservedObject internal var vm: LookupRootVM
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            sidebar: sidebar,
            content: content,
            detail: detail
        )
        .searchable(text: $vm.searchText, placement: .toolbar)
        .navigationTitle(vm.title)
    }
    
    @ViewBuilder
    private func sidebar() -> some View {
        List(vm.kernelRows, id: \.self, selection: $vm.selectedKernel) { kernel in
            NavigationLink(value: kernel) {
                Text(kernel)
            }
        }
        .navigationSplitViewColumnWidth(150.0)
    }
    
    @ViewBuilder
    private func content() -> some View {
        LookupKernelInfoView(
            selectedTag: $vm.selectedTag,
            list: $vm.tagList
        )
        .navigationSplitViewColumnWidth(min: detailWidth, ideal: detailWidth)
    }
     
    @ViewBuilder
    private func detail() -> some View {
        if let selectedTag = vm.selectedTag {
            TagDetailsView(
                vm: vm.detailVM(for: selectedTag)
            )
        } else {
            Text("No Tag Selected")
                .font(.largeTitle)
                .fontWeight(.light)
                .foregroundStyle(.tertiary)
        }
    }

}

struct LookupRootView_Previews: PreviewProvider {
    
    static var previews: some View {
        LookupRootView(
            vm: .init(
                tagParser: TagParser(tagDecoder: AppVM().tagDecoder),
                selectedTagIdx: 220
            )
        ).frame(width: 1000.0)
    }
}
