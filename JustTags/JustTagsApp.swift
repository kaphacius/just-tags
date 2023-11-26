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
    @FocusedBinding(\.currentWindow) private var currentWindow
    
    internal var body: some Scene {
        WindowGroup("Main", id: WindowType.main.rawValue, for: MainVM.ID.self) { $vmId in
            MainWindow(
                vmProvider: appVM,
                vmId: $vmId
            )
            .blur(radius: appVM.setUpInProgress ? 30.0 : 0.0)
            .overlay {
                if appVM.setUpInProgress {
                    ProgressView().progressViewStyle(.circular)
                }
            }
            .environmentObject(appVM)
        } defaultValue: {
            appVM.createNewMainVM().id
        }
        .commands {
            MainViewCommands(vm: appVM)
        }.onChange(of: currentWindow) { _, newValue in
            appVM.currentWindow = newValue
        }
        
        WindowGroup("Diff", id: WindowType.diff.rawValue, for: DiffVM.ID.self) { $vmId in
            DiffWindow(
                vmProvider: appVM,
                vmId: $vmId
            ).environmentObject(appVM)
        } defaultValue: {
            appVM.createNewDiffVM().id
        }
        
        Window("Tag Library", id: WindowType.library.rawValue) {
            LibraryView(
                tagParser:  TagParser(tagDecoder: AppVM.shared.tagDecoder)
            )
        }.keyboardShortcut("L", modifiers: [.command, .shift])
        
        Settings {
            SettingsView(selectedTab: $appVM.selectedTab)
                .environmentObject(appVM.kernelInfoRepo!)
                .environmentObject(appVM.tagMappingRepo!)
        }
    }

}
