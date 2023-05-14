//
//  Command.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 14/05/2023.
//

import SwiftUI

enum Command {
    case about
    case copySelectedTags
    case paste
    case pasteIntoNewTab
    case selectAll
    case deselectAll
    case newTabButton
    case renameTab
    case openMainView
    case openDiffView
    case openTagLibrary
    case addKernelInfo
    case diffSelectedTags
    case whatsNew
    case releaseNotes
    case keyBindings
    
    enum Group: Equatable, CaseIterable {
        case about
        case file
        case edit
        case diff
        case help
        case undoRedo
        
        var commands: [Command] {
            switch self {
            case .about:
                return [.about]
            case .file:
                return [
                    .newTabButton,
                    .renameTab,
                    .openMainView,
                    .openDiffView,
                    .openTagLibrary,
                    .addKernelInfo
                ]
            case .edit:
                return [
                    .copySelectedTags,
                    .paste,
                    .pasteIntoNewTab,
                    .selectAll,
                    .deselectAll
                ]
            case .diff:
                return [.diffSelectedTags]
            case .help:
                return [
                    .whatsNew,
                    .releaseNotes,
                    .keyBindings
                ]
            case .undoRedo:
                return []
            }
        }
        
        var replacing: CommandGroupPlacement {
            switch self {
            case .about: return .appInfo
            case .file: return .newItem
            case .edit: return .pasteboard
            case .diff: return .undoRedo
            case .help: return .help
            case .undoRedo: return .undoRedo
            }
        }
    }
    
}

extension WindowType {
    
    var commands: [Command] {
        switch self {
        case .main:
            return [
                .about,
                .copySelectedTags,
                .paste,
                .pasteIntoNewTab,
                .selectAll,
                .deselectAll,
                .newTabButton,
                .renameTab,
                .openMainView,
                .openDiffView,
                .openTagLibrary,
                .addKernelInfo,
                .diffSelectedTags,
                .whatsNew,
                .releaseNotes,
                .keyBindings
            ]
        case .diff:
            return [
                .about,
                .paste,
                .pasteIntoNewTab,
                .newTabButton,
                .renameTab,
                .openMainView,
                .openDiffView,
                .openTagLibrary,
                .addKernelInfo,
                .whatsNew,
                .releaseNotes,
                .keyBindings
            ]
        case .library:
            return [
                .about,
                .openMainView,
                .openDiffView,
                .openTagLibrary,
                .addKernelInfo,
                .whatsNew,
                .releaseNotes,
                .keyBindings
            ]
        }
    }
    
}
