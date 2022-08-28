//
//  AppVM+Persistence.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/08/2022.
//

import Foundation

extension AppVM {
    
    internal func saveAppState() {
        var mains: [MainWindowVM] = []
        var activeTab: Int?
        
        windows
            .map(\.windowNumber)
            .compactMap { t2FlatMap(($0, viewModels[$0])) }
            .compactMap { t2FlatMap(($0.0, $0.1 as? MainWindowVM)) }
            .enumerated()
            .map { ($0.offset, $0.element.1) }
            .forEach { (windowIdx: Int, vm: MainWindowVM) in
                mains.append(vm)
                if activeTab == nil && activeVM === vm {
                    activeTab = windowIdx
                }
            }
        
        let appState = AppState(
            mains: mains.map(MainWindowState.init(windowVM:)),
            activeTab: activeTab ?? 0
        )
        
        AppState.save(state: appState)
    }
    
}