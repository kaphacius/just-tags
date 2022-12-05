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
    @EnvironmentObject private var kernelInfoRepo: KernelInfoRepo
    @EnvironmentObject private var tagMappingRepo: TagMappingRepo
    
    var body: some View {
        TabView(selection: $selectedTab) {
            kernels.tag(Tab.kernels)
            tagMappings.tag(Tab.tagMappings)
            keyBindings.tag(Tab.keyBindings)
        }
        .navigationTitle("Settings")
        .padding(commonPadding)
        .frame(width: 600.0, height: 450.0)
    }
    
    private var kernels: some View {
        CustomResourceListView(vm: .init(repo: kernelInfoRepo))
            .tabItem {
                Label(KernelInfo.settingsPage, systemImage: KernelInfo.iconName)
            }
    }
    
    private var tagMappings: some View {
        CustomResourceListView(vm: .init(repo: tagMappingRepo))
            .tabItem {
                Label(TagMapping.settingsPage, systemImage: TagMapping.iconName)
            }
    }
    
    private var keyBindings: some View {
        ShortcutListView(lines: shortcuts)
            .tabItem {
                Label("Key Bindings", systemImage: "keyboard")
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
        SettingsView(selectedTab: .constant(.tagMappings))
            .environmentObject(PreviewHelpers.kernelInfoRepo)
            .environmentObject(PreviewHelpers.tagMappingRepo)
    }
}
