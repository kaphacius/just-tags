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
    
    var body: some View {
        TabView {
            general
            kernels
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
    
    private func page<H: CustomResourceHandler>(
        vm: CustomResourceListVM<H>
    ) -> some View {
        CustomResourceListView(vm: vm)
            .tabItem {
                Label(H.Resource.settingsPage, systemImage: H.Resource.iconName)
            }
    }
    
    private var kernels: some View {
        page(
            vm: .init(repo: kernelInfoRepo)
        )
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(try! TagDecoder.defaultDecoder())
    }
}
