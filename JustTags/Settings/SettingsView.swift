//
//  SettingsView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 14/10/2022.
//

import SwiftUI
import SwiftyEMVTags

struct SettingsView: View {
    
    @Binding var selectedTab: Tab
    internal let kernelInfoRepo: KernelInfoRepo?
    internal let tagMappingRepo: TagMappingRepo?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            if let kernelInfoRepo {
                kernels(repo: kernelInfoRepo).tag(Tab.kernels)
            }
            
            if let tagMappingRepo {
                tagMappings(repo: tagMappingRepo).tag(Tab.tagMappings)
            }
            
            keyBindings.tag(Tab.keyBindings)
        }
        .navigationTitle("Settings")
        .padding(commonPadding)
        .frame(width: 600.0, height: 450.0)
    }
    
    private func kernels(repo: KernelInfoRepo) -> some View {
        CustomResourceListView(vm: .init(repo: repo))
            .tabItem {
                Label(KernelInfo.settingsPage, systemImage: KernelInfo.iconName)
            }
    }
    
    private func tagMappings(repo: TagMappingRepo) -> some View {
        CustomResourceListView(vm: .init(repo: repo))
            .tabItem {
                Label(TagMapping.settingsPage, systemImage: TagMapping.iconName)
            }
    }
    
    private var keyBindings: some View {
        ShortcutListView(lines: shortcuts)
            .tabItem {
                Label("Key Bindings", systemImage: "keyboard.fill")
            }
    }
}

extension SettingsView {
    
    internal enum Tab: Hashable {
        
        case kernels
        case tagMappings
        case keyBindings
        
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(
            selectedTab: .constant(.tagMappings),
            kernelInfoRepo: PreviewHelpers.kernelInfoRepo,
            tagMappingRepo: PreviewHelpers.tagMappingRepo
        )
    }
}
