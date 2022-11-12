//
//  CustomResourceList.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 09/11/2022.
//

import SwiftUI

struct CustomResourceListView<
    Handler: CustomResourceHandler,
    ResourceView: CustomResourceView
>: View where Handler.Resource == ResourceView.Resource {
    @ObservedObject internal var vm: CustomResourceListVM<Handler>
    
    var body: some View {
        VStack(alignment: .leading, spacing: commonPadding) {
            existingInfoList
            addNewInfo
        }
        .padding(commonPadding)
        .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop(_:))
    }
    
    private var addNewInfo: some View {
        Button(action: toggleOpenPanel) {
            Label("Add custom \(Handler.Resource.displayName)...", systemImage: "plus")
        }
    }
    
    private var existingInfoList: some View {
        ScrollView {
            Divider()
            ForEach(vm.resources, id: \.identifier) { resource in
                HStack {
                    ResourceView(resource: resource)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topTrailing) {
                    deleteButtonOverlay(for: resource.identifier)
                }
                Divider()
            }
        }
    }
    
    @ViewBuilder
    private func deleteButtonOverlay(for identifier: String) -> some View {
        if vm.shouldShowDeleteButton(for: identifier) {
            Button(action: {
                // TODO: Add confirmation to deletion
                try! vm.removeResource(with: identifier)
            }) {
                Label("Delete \(identifier)", systemImage: "xmark.bin.fill")
                    .labelStyle(.iconOnly)
            }.padding(.trailing, commonPadding)
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(
            ofClass: NSPasteboard.PasteboardType.self
        ) { (pasteboardItem, error) in
            guard let pasteboardItem,
                  let url = URL(string: pasteboardItem.rawValue) else {
                // TODO: handle error
                return
            }
            
            // TODO: handle error
            try? vm.addNewResource(at: url)
        }
        return true
    }
    
    private func toggleOpenPanel() {
        do {
            let openPanel = NSOpenPanel()
            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles = true
            openPanel.allowedContentTypes = [.json]
            guard openPanel.runModal() == .OK else { return }
            
            guard let infoURL = openPanel.url else { return }
            
            try vm.addNewResource(at: infoURL)
        } catch {
            // TODO: handle error
            print(error)
        }
    }
}

//struct CustomResourceList_Previews: PreviewProvider {
//    static var previews: some View {
//        CustomResourceList()
//    }
//}
