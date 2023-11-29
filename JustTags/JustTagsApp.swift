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
    @FocusedValue(\.currentWindow) private var currentWindow
    
    internal var body: some Scene {
        WindowGroup(
            WindowType.Case.main.title,
            id: WindowType.Case.main.id,
            for: MainVM.ID.self
        ) { $vmId in
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
            // WWDC 2024
            // Why is this called when id passed in?
            appVM.vmIdToOpen(for: .main)
        }
        .commands {
            MainViewCommands(vm: appVM)
        }.onChange(of: currentWindow) { _, newValue in
            appVM.currentWindow = newValue
        }
        
        WindowGroup(
            WindowType.Case.diff.title,
            id: WindowType.Case.diff.id,
            for: DiffVM.ID.self
        ) { $vmId in
            DiffWindow(
                vmProvider: appVM,
                vmId: $vmId
            ).environmentObject(appVM)
        } defaultValue: {
            // WWDC 2024
            // Why is this called when id passed in?
            appVM.vmIdToOpen(for: .diff)
        }
        
        Window(
            WindowType.Case.library.title,
            id: WindowType.Case.library.id
        ) {
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
