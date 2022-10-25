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
    
    var body: some View {
        VStack(alignment: .leading, spacing: commonPadding) {
            existingInfoList
            addNewInfo
        }
        .padding(commonPadding)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(
                ofClass: NSPasteboard.PasteboardType.self) { (pasteboardItem, error) in
                    guard let pasteboardItem,
                          let url = URL(string: pasteboardItem.rawValue) else {
                        // TODO: handle error
                        return
                    }
                    
                    try? addNewKernelInfo(at: url)
                }
            return true
        }
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
                }.frame(maxWidth: .infinity)
                Divider()
            }
        }
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
            
            try addNewKernelInfo(at: infoURL)
        } catch {
            // TODO: handle error
            print(error)
        }
    }
    
    private func addNewKernelInfo(at url: URL) throws {
        let data = try Data(contentsOf: url)
        try tagDecoder.addKernelInfo(data: data)
        saveNewKernelInfo(url: url)
        Task { @MainActor in
            tagDecoder.objectWillChange.send()
        }
    }
    
    private func saveNewKernelInfo(url: URL) {
        guard let supportFolder = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory, .userDomainMask, true)
            .first
            .map(URL.init(fileURLWithPath:))
        else {
            return
        }
        
        do {
            let dirPath = supportFolder
                .appendingPathComponent("KernelInfo", isDirectory: true)
            if FileManager.default.fileExists(atPath: dirPath.path) == false {
                try FileManager.default.createDirectory(
                    at: dirPath,
                    withIntermediateDirectories: false
                )
            }
            
            try FileManager.default.copyItem(
                at: url,
                to: dirPath.appendingPathComponent(url.lastPathComponent)
            )
        } catch {
            // TODO: handle errors
            print(error)
        }
    }
}

struct KernelsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        KernelsSettingsView()
            .environmentObject(try! TagDecoder.defaultDecoder())
    }
}
