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
                .handlesExternalEvents(
                    preferring: [WindowType.main.eventIdentifier],
                    allowing: [WindowType.main.eventIdentifier]
                )
        }
        .commands {
            MainViewCommands(vm: appVM)
        }
        .handlesExternalEvents(matching: [WindowType.main.eventIdentifier])
        
        WindowGroup {
            DiffView()
                .environmentObject(appVM)
                .handlesExternalEvents(
                    preferring: [WindowType.diff.eventIdentifier],
                    allowing: [WindowType.diff.eventIdentifier]
                )
        }
        .handlesExternalEvents(matching: [WindowType.diff.eventIdentifier])
        
        WindowGroup {
            LibraryView(
                vm: .init(tagParser: TagParser(tagDecoder: appVM.tagDecoder))
            )
            .handlesExternalEvents(
                preferring: [WindowType.library.eventIdentifier],
                allowing: [WindowType.library.eventIdentifier]
            )
        }
        .handlesExternalEvents(matching: [WindowType.library.eventIdentifier])
        
        Settings {
            SettingsView(selectedTab: $appVM.selectedTab)
                .environmentObject(appVM.kernelInfoRepo!)
                .environmentObject(appVM.tagMappingRepo!)
        }
    }

}
