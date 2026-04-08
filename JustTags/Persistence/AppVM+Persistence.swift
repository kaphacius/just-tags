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

        let libraryState = libraryVM.map(LibraryWindowState.init)
        let isLibraryActive = currentWindow == .library

        let appState = AppState(
            mains: mainStates,
            activeTab: mainVMs.firstIndex(where: { $0.value === currentWindow?.asMainVM }) ?? 0,
            library: libraryState,
            activeWindowIsLibrary: isLibraryActive
        )

        AppState.save(state: appState)
    }

}
