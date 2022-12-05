//
//  JustTagsApp.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 20/03/2022.
//

import SwiftUI
import SwiftyEMVTags

@main
internal struct JustTagsApp: App {
    
    @StateObject private var appVM = AppVM()
    
    internal var body: some Scene {
        WindowGroup {
            MainView()
                .blur(radius: appVM.setUpInProgress ? 30.0 : 0.0)
                .overlay {
                    if appVM.setUpInProgress {
                        ProgressView().progressViewStyle(.circular)
                    }
                }
                .environmentObject(appVM)
                .handlesExternalEvents(preferring: ["main"], allowing: ["main"])
        }
        .commands {
            MainViewCommands(vm: appVM)
        }
        .handlesExternalEvents(matching: ["main"])
        
        
        WindowGroup("Diff") {
            DiffView()
                .environmentObject(appVM)
                .handlesExternalEvents(preferring: ["diff"], allowing: ["diff"])
        }.handlesExternalEvents(matching: ["diff"])
        
        Settings {
            SettingsView(selectedTab: $appVM.selectedTab)
                .environmentObject(appVM.kernelInfoRepo!)
                .environmentObject(appVM.tagMappingRepo!)
        }
    }

}
