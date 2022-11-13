//
//  SettingsView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 14/10/2022.
//

import SwiftUI
import SwiftyEMVTags

struct SettingsView: View {
    
    @EnvironmentObject private var kernelInfoRepo: KernelInfoRepo
    @EnvironmentObject private var tagMappingRepo: TagMappingRepo
    
    var body: some View {
        TabView {
            general
            kernels
            tagMappings
        }
        .navigationTitle("Settings")
        .padding(commonPadding)
        .frame(width: 600.0, height: 450.0)
    }
    
    private var general: some View {
        Text("Here be General settings")
            .font(.largeTitle)
            .tabItem {
                Label("General", systemImage: "gear")
            }
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
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(PreviewHelpers.kernelInfoRepo)
            .environmentObject(PreviewHelpers.tagMappingRepo)
    }
}
