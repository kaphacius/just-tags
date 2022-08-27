//
//  AppVM+Persistence.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/08/2022.
//

import Foundation

extension AppVM {
    
    internal func saveAppState() throws {
        var mains: [MainWindowVM] = []
        var diffs: [DiffWindowVM] = []
        var activeWindow: AppState.ActiveWindow? = nil
        
        viewModels.forEach { (windowNumber: Int, vm: AnyWindowVM) in
            if let main = vm as? MainWindowVM {
                mains.append(main)
                if activeWindow == nil && activeVM === vm {
                    activeWindow = windows
                        .map(\.windowNumber)
                        .firstIndex(of: windowNumber)
                        .map(AppState.ActiveWindow.main)
                }
            } else if let diff = vm as? DiffWindowVM {
                diffs.append(diff)
                if activeWindow == nil && activeVM === vm {
                    activeWindow = windows
                        .map(\.windowNumber)
                        .firstIndex(of: windowNumber)
                        .map(AppState.ActiveWindow.diff)
                }
            }
        }
        
        let appState = AppState(
            mains: mains.map(MainWindowState.init(windowVM:)),
            diffs: diffs.map(DiffWindowState.init(diffWindowVM:)),
            activeWindow: activeWindow ?? .main(0)
        )
        
        AppState.save(state: appState)
    }
    
}
