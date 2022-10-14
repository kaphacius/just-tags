//
//  SettingsView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 14/10/2022.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            ProfileSettingsView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
            
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintpalette")
                }
            
            PrivacySettingsView()
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }
        }
        .frame(width: 450, height: 250)
    }
}

struct ProfileSettingsView: View {
    var body: some View {
        Text("Profile Settings")
            .font(.title)
    }
}


struct AppearanceSettingsView: View {
    var body: some View {
        Text("Appearance Settings")
            .font(.title)
    }
}


struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
            .font(.title)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
