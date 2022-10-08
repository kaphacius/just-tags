//
//  AppState.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/08/2022.
//

import Foundation

internal struct AppState: Codable {
    
    private var mains: [MainWindowState]
    internal let activeTab: Int
    
    internal init(
        mains: [MainWindowState],
        activeTab: Int
    ) {
        self.mains = mains
        self.activeTab = activeTab
    }
    
    internal static let empty: AppState = .init(mains: [], activeTab: 0)
    
    mutating internal func nextMainState() -> MainWindowState? {
        mains.isEmpty ? nil : mains.removeFirst()
    }
    
    internal var isStateRestored: Bool {
        mains.isEmpty
    }
    
    internal static func save(state: AppState) {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: try stateFileURL)
        } catch {
            print("Error saving state", error)
        }

    }
    
    internal static func loadState() -> AppState {
        do {
            let fileHandle = try FileHandle(forReadingFrom: stateFileURL)
            let loadedAppState = try JSONDecoder().decode(AppState.self, from: fileHandle.availableData)
            print("Loaded state with \(loadedAppState.mains.count) objects")
            return loadedAppState
        } catch {
            print("Error loading state", error)
            return .empty
        }
    }
    
    private static var stateFileURL: URL {
        get throws {
            try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            ).appendingPathComponent("state.data")
        }
    }
    
}

internal struct MainWindowState: Codable {
    
    internal let title: String
    internal let tagsHexString: String
    
    internal init(windowVM vm: MainVM) {
        self.title = vm.title
        self.tagsHexString = vm.initialTags.map(\.fullHexString).joined()
    }
    
}
