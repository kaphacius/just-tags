//
//  AppState.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/08/2022.
//

import Foundation

internal struct AppState: Codable {
    
    internal enum ActiveWindow: Codable {
        case main(Int)
        case diff(Int)
    }
    
    internal let mains: [MainWindowState]
    internal let diffs: [DiffWindowState]
    internal let activeWindow: ActiveWindow
    
    internal static func save(state: AppState) {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: try stateFileURL)
        } catch {
            print("Error saving state", error)
        }

    }
    
    internal static func loadState() -> AppState? {
        do {
            let fileHandle = try FileHandle(forReadingFrom: stateFileURL)
            return try JSONDecoder().decode(AppState.self, from: fileHandle.availableData)
        } catch {
            print("Error loading state", error)
            return nil
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
    
    internal init(windowVM vm: MainWindowVM) {
        self.title = vm.title
        self.tagsHexString = vm.initialTags.map(\.hexString).joined()
    }
    
}

internal struct DiffWindowState: Codable {
    
    internal let title: String
    internal let texts: [String]
    internal let showsOnlyDifferent: Bool
    
    internal init(diffWindowVM vm: DiffWindowVM) {
        self.title = vm.title
        self.texts = vm.texts
        self.showsOnlyDifferent = vm.showOnlyDifferent
    }
    
}
