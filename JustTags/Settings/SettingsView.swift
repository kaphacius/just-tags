//
//  SettingsView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 14/10/2022.
//

import SwiftUI
import SwiftyEMVTags

struct SettingsView: View {
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
    
    private var kernels: some View {
        KernelsSettingsView()
            .tabItem {
                Label("Kernels", systemImage: "text.book.closed.fill")
            }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(try! TagDecoder.defaultDecoder())
    }
}
