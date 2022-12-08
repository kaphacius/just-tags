//
//  Shortcuts.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 04/12/2022.
//

import Foundation

internal let shortcuts: [ShortcutVM] = [
    .init(title: "Open New Tab", key: "T", modifiers: .command),
    .init(title: "Open Current Tab", key: "W", modifiers: .command),
    .init(title: "Open Main Window", key: "M", modifiers: [.command, .shift]),
    .init(title: "Open Diff Window", key: "D", modifiers: [.command, .shift]),
    .init(title: "Open Preferences", key: ",", modifiers: [.command]),
    .init(title: "Rename Tab", key: "R", modifiers: [.command, .shift]),
    .init(title: "Paste in Current Tab", key: "V", modifiers: .command),
    .init(title: "Paste in New Tab", key: "V", modifiers: [.command, .shift]),
    .init(title: "Copy Selected Tag(s)", key: "C", modifiers: [.command]),
    .init(title: "Select All Tags", key: "A", modifiers: [.command]),
    .init(title: "Add Custom Kernel Info", key: "O", modifiers: [.command, .shift]),
    .init(title: "Show Active Kernels", key: "K", modifiers: [.command, .shift]),
    .init(title: "Diff Selected Tags", key: "D", modifiers: [.option, .shift]),
    .init(title: "Toggle Show Only Different Tags", key: "T", modifiers: [.command, .shift]),
    .init(title: "Flip Diffed Tags", key: "F", modifiers: [.command, .shift])
]
