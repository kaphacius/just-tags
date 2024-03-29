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
        
        let appState = AppState(
            mains: mainStates,
            activeTab: mainVMs.firstIndex(where: { $0 === currentWindow?.asMainVM }) ?? 0
        )
        
        AppState.save(state: appState)
    }
    
}
