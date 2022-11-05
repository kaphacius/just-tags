//
//  KernelsInfo.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 14/10/2022.
//

import SwiftUI
import SwiftyEMVTags

extension TagDecoder: ObservableObject {}

struct KernelsSettingsView: View {
    @EnvironmentObject private var tagDecoder: TagDecoder
    @EnvironmentObject private var repo: CustomResourceRepo<KernelInfoHandler>
    
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
            Label("Add custom kernel info...", systemImage: "plus")
        }
    }
    
    private var existingInfoList: some View {
        ScrollView {
            Divider()
            ForEach(kernelInfoVMs, id: \.name) { vm in
                HStack {
                    KernelInfoView(vm: vm)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topTrailing) {
                    deleteButtonOverlay(for: vm.name)
                }
                Divider()
            }
        }
    }
    
    @ViewBuilder
    private func deleteButtonOverlay(for name: String) -> some View {
        if repo.resources.contains(name) {
            Button(action: {
                // TODO: Add confirmation to deletion
                try! repo.removeResource(with: name)
            }) {
                Label("Delete \(name)", systemImage: "xmark.bin.fill")
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
            try? repo.addNewResource(at: url)
        }
        return true
    }
    
    private var kernelInfoVMs: [KernelInfoVM] {
        tagDecoder
            .kernelsInfo
            .values
            .sorted(by: { (lhs, rhs) in
                lhs.name < rhs.name
            }).map(\.kernelInfoVM)
    }
    
    private func toggleOpenPanel() {
        do {
            let openPanel = NSOpenPanel()
            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles = true
            openPanel.allowedContentTypes = [.json]
            guard openPanel.runModal() == .OK else { return }
            
            guard let infoURL = openPanel.url else { return }
            
            try repo.addNewResource(at: infoURL)
        } catch {
            // TODO: handle error
            print(error)
        }
    }
    
}

struct KernelsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        KernelsSettingsView()
            .environmentObject(try! TagDecoder.defaultDecoder())
            .environmentObject(
                CustomResourceRepo(
                    handler: KernelInfoHandler(tagDecoder: try! TagDecoder.defaultDecoder())
                )!
            )
    }
}
