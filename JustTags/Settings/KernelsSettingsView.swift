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
            Divider()
            existingInfoList
            addNewInfo
        }.padding(commonPadding)
    }
    
    private var addNewInfo: some View {
        Button(action: addNewKernelInfo) {
            Label("Add custom kernel info...", systemImage: "plus")
        }
    }
    
    private var existingInfoList: some View {
        ScrollView {
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
    
    internal func addNewKernelInfo() {
        do {
            let openPanel = NSOpenPanel()
            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles = true
            openPanel.allowedContentTypes = [.json]
            guard openPanel.runModal() == .OK else { return }
            
            guard let infoURL = openPanel.url else { return }
            
            let data = try Data(contentsOf: infoURL)
            try tagDecoder.addKernelInfo(data: data)
            tagDecoder.objectWillChange.send()
        } catch {
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
