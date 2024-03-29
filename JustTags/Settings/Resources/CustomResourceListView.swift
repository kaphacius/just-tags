//
//  CustomResourceList.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 09/11/2022.
//

import SwiftUI
import SwiftyEMVTags

struct CustomResourceListView<Resource: CustomResource>: View {
    
    @ObservedObject internal var vm: CustomResourceListVM<Resource>
    @State private var alert: PresentableAlert?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: commonPadding * 2) {
                HStack {
                    addNew
                    Spacer()
                    clearAll
                }
                existingInfoList
            }
            .padding(commonPadding)
        }
        .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop(_:))
        .animation(.default, value: vm.resources.map(\.id))
        .errorAlert($alert)
    }
    
    private var addNew: some View {
        Button(action: toggleOpenPanel) {
            Label("Add custom \(Resource.displayName)...", systemImage: "plus")
        }
    }
    
    private var clearAll: some View {
        Button {
            // TODO: Add confirmation to deletion
            do {
                try vm.clearSavedResources()
            } catch {
                self.alert = .init(error: error)
            }
        } label: {
            Label("Clear all \(Resource.displayName)s", systemImage: "trash.fill")
        }
    }
    
    private var existingInfoList: some View {
        ForEach(vm.resources) { resource in
            GroupBox {
                Resource.View(resource: resource)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .topTrailing) {
                        deleteButtonOverlay(for: resource.id)
                    }
            }
        }
    }
    
    @ViewBuilder
    private func deleteButtonOverlay(for identifier: Resource.ID) -> some View {
        if vm.shouldShowDeleteButton(for: identifier) {
            Button(action: {
                // TODO: Add confirmation to deletion
                do {
                    try vm.removeResource(with: identifier)
                } catch {
                    self.alert = .init(error: error)
                }
            }) {
                Label("Delete", systemImage: "xmark.bin.fill")
                    .labelStyle(.iconOnly)
            }.padding(.trailing, commonPadding)
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        providers.forEach { provider in
            _ = provider.loadObject(
                ofClass: NSPasteboard.PasteboardType.self
            ) { (pasteboardItem, error) in
                do {
                    guard let pasteboardItem,
                          let url = URL(string: pasteboardItem.rawValue) else {
                        throw JustTagsError(message: "Unable to extract file URL for dropped resource")
                    }
                    
                    try vm.addNewResource(at: url)
                } catch {
                    self.alert = .init(error: error)
                }
            }
        }
        
        return true
    }
    
    private func toggleOpenPanel() {
        do {
            let openPanel = NSOpenPanel()
            openPanel.canChooseDirectories = false
            openPanel.canChooseFiles = true
            openPanel.allowsMultipleSelection = true
            openPanel.allowedContentTypes = [.json]
            guard openPanel.runModal() == .OK else { return }
            try openPanel.urls.forEach(vm.addNewResource(at:))
        } catch {
            self.alert = .init(error: error)
        }
    }
}

struct CustomResourceList_Previews: PreviewProvider {
    static var previews: some View {
        CustomResourceListView<KernelInfo>(
            vm: .init(repo: PreviewHelpers.kernelInfoRepo)
        )
        CustomResourceListView<TagMapping>(
            vm: .init(repo: PreviewHelpers.tagMappingRepo)
        )
    }
}
