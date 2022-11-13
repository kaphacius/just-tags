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
    @State private var alert: PresentableAlert?
    
    var body: some View {
        TabView {
            kernels
            tagMappings
        }
        .navigationTitle("Settings")
        .padding(commonPadding)
        .frame(width: 600.0, height: 450.0)
        .onPreferenceChange(AlertPreferenceKey.self) { self.alert = $0 }
    }
    
    private var general: some View {
        Text("Here be General settings")
            .font(.largeTitle)
            .tabItem {
                Label("General", systemImage: "gear")
            }
    }
    
    private func page<H: CustomResourceHandler, V: CustomResourceView>(
        vm: CustomResourceListVM<H>,
        viewType: V.Type
    ) -> some View where H.Resource == V.Resource {
        CustomResourceListView<H, V>(vm: vm)
            .tabItem {
                Label(H.Resource.settingsPage, systemImage: H.Resource.iconName)
            }
    }
    
    private var kernels: some View {
        page(
            vm: .init(repo: kernelInfoRepo),
            viewType: KernelInfoView.self
        )
    }
    
    private var tagMappings: some View {
        page(
            vm: .init(repo: tagMappingRepo),
            viewType: TagMappingView.self
        )
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
