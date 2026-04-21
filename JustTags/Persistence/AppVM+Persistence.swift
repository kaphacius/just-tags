//
//  AppVM+Persistence.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/08/2022.
//

import AppKit

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
        let activeWindowInfo = Self.activeWindowInfo(
            mainStates: mainStates,
            diffStates: diffStates,
            mainVMs: mainVMs,
            diffVMs: diffVMs,
            currentWindow: currentWindow
        )

        let appState = AppState(
            mains: mainStates,
            diffs: diffStates,
            library: libraryState,
            activeWindowInfo: activeWindowInfo
        )

        AppState.save(state: appState)
    }

    private static func activeWindowInfo(
        mainStates: [MainWindowState],
        diffStates: [DiffWindowState],
        mainVMs: [WNS<MainVM>],
        diffVMs: [WNS<DiffVM>],
        currentWindow: WindowType?
    ) -> ActiveWindowInfo {
        if NSApp.keyWindow?.title == WindowType.Case.library.title {
            return .library
        }

        let nonEmptyMainVMs = mainVMs.compactMap(\.value).filter { $0.isEmpty == false }
        let nonEmptyDiffVMs = diffVMs.compactMap(\.value).filter { $0.isEmpty == false }

        if let mainVM = currentWindow?.asMainVM,
           let idx = nonEmptyMainVMs.firstIndex(where: { $0 === mainVM }) {
            return .main(idx)
        }

        if let cw = currentWindow, case .diff(let wns) = cw,
           let diffVM = wns.value,
           let idx = nonEmptyDiffVMs.firstIndex(where: { $0 === diffVM }) {
            return .diff(idx)
        }

        return .main(0)
    }

}
