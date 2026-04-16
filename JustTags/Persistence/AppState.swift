//
//  AppState.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/08/2022.
//

import Foundation

internal enum ActiveWindow: String, Codable {
    case main
    case library
}

internal struct AppState: Codable {

    private var mains: [MainWindowState]
    private var diffs: [DiffWindowState]
    internal let library: LibraryWindowState?
    internal let activeWindow: ActiveWindow?

    private enum CodingKeys: String, CodingKey {
        case mains, diffs, library, activeWindow
    }

    internal init(
        mains: [MainWindowState],
        diffs: [DiffWindowState],
        library: LibraryWindowState?,
        activeWindow: ActiveWindow
    ) {
        self.mains = mains
        self.diffs = diffs
        self.library = library
        self.activeWindow = activeWindow
    }

    // Custom Codable so that older saved states without `diffs` still load cleanly.
    internal init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.mains = try c.decode([MainWindowState].self, forKey: .mains)
        self.diffs = try c.decodeIfPresent([DiffWindowState].self, forKey: .diffs) ?? []
        self.library = try c.decodeIfPresent(LibraryWindowState.self, forKey: .library)
        self.activeWindow = try c.decodeIfPresent(ActiveWindow.self, forKey: .activeWindow)
    }

    internal func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(mains, forKey: .mains)
        try c.encode(diffs, forKey: .diffs)
        try c.encodeIfPresent(library, forKey: .library)
        try c.encodeIfPresent(activeWindow, forKey: .activeWindow)
    }

    internal static let empty: AppState = .init(
        mains: [],
        diffs: [],
        library: nil,
        activeWindow: .main
    )

    mutating internal func nextMainState() -> MainWindowState? {
        mains.isEmpty ? nil : mains.removeFirst()
    }

    mutating internal func nextDiffState() -> DiffWindowState? {
        diffs.isEmpty ? nil : diffs.removeFirst()
    }

    internal var isStateRestored: Bool {
        mains.isEmpty
    }

    internal var hasDiffStates: Bool {
        diffs.isEmpty == false
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

internal struct LibraryWindowState: Codable {

    internal let searchText: String
    internal let inputString: String
    internal let selectedTagId: UInt64?
    internal let selectedKernelId: String?
    internal let selectedTagContext: UInt64?

}

internal struct MainWindowState: Codable {

    internal let title: String
    internal let tagsHexString: String

    internal init(windowVM vm: MainVM) {
        self.title = vm.title
        self.tagsHexString = vm.initialTags.map(\.fullHexString).joined()
    }

}

extension LibraryWindowState {

    internal init(vm: LibraryVM) {
        self.searchText = vm.searchText
        self.inputString = vm.inputString
        self.selectedTagId = vm.selectedTag?.info.tag
        self.selectedKernelId = vm.selectedTag?.info.kernel
        self.selectedTagContext = vm.selectedTag?.info.context
    }

}

internal struct DiffWindowState: Codable {

    internal let texts: [String]

    internal init(vm: DiffVM) {
        self.texts = vm.texts
    }

}
