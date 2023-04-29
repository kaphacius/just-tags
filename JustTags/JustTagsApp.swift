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
    
    @StateObject private var appVM: AppVM = .shared
    @FocusedObject private var mainVM: MainVM?
    
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
        
        WindowGroup {
            DiffView()
                .environmentObject(appVM)
                .handlesExternalEvents(preferring: ["diff"], allowing: ["diff"])
        }.handlesExternalEvents(matching: ["diff"])
        
        WindowGroup {
            LibraryView(
                vm: .init(tagParser: TagParser(tagDecoder: appVM.tagDecoder))
            )
            .handlesExternalEvents(preferring: ["library"], allowing: ["library"])
        }.handlesExternalEvents(matching: ["library"])
        
        Settings {
            SettingsView(selectedTab: $appVM.selectedTab)
                .environmentObject(appVM.kernelInfoRepo!)
                .environmentObject(appVM.tagMappingRepo!)
        }
    }

}
