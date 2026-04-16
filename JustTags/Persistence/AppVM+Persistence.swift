//
//  AppVM+Persistence.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/08/2022.
//

import Foundation

extension AppVM {

    internal func saveAppState() {
        let mainStates: [MainWindowState] = mainVMs
            .compactMap(\.value)
            .filter { $0.isEmpty == false }
            .map(MainWindowState.init)

        let diffStates: [DiffWindowState] = diffVMs
            .compactMap(\.value)
            .filter { $0.isEmpty == false }
            .map(DiffWindowState.init)

        let libraryState = libraryVM.map(LibraryWindowState.init)
        let activeWindow: ActiveWindow = currentWindow?.type == .library ? .library : .main

        let appState = AppState(
            mains: mainStates,
            diffs: diffStates,
            library: libraryState,
            activeWindow: activeWindow
        )

        AppState.save(state: appState)
    }

}
