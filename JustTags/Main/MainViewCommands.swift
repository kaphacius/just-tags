//
//  MainViewCommands.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 05/06/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct MainViewCommands: Commands {
    
    @FocusedBinding(\.selectedTags) private var selectedTags
    @FocusedBinding(\.tabName) private var tabName
    @FocusedBinding(\.mainVM) private var mainVM
    @Environment(\.openWindow) private var openWindow
    @FocusedValue(\.currentWindow) private var currentWindow
    
    @ObservedObject internal var vm: AppVM
    
    internal var body: some Commands {
        commandGroup(for: .about)
        commandGroup(for: .file)
        commandGroup(for: .edit)
        commandGroup(for: .diff)
        commandGroup(for: .help)
        commandGroup(for: .undoRedo)
    }
    
    @CommandsBuilder
    internal func commandGroup(for group: Command.Group) -> some Commands {
        CommandGroup(replacing: group.replacing) {
            ForEach(group.commands, id: \.self) { command in
                commandView(for: command)
            }
        }
    }
    
    private var diffSelectedTags: some View {
        Button(
            "Diff selected tags",
            action: vm.diffSelectedTags
        ).keyboardShortcut("d", modifiers: [.option, .shift])
    }
    
    private var copySelectedTags: some View {
        Button(action: {
            selectedTags
                .map(\.hexString)
                .map(NSPasteboard.copyString)
        }, label: {
            Text(selectedTags.moreThanOne ? "Copy selected tags" : "Copy selected tag")
        })
        .disabled(selectedTags.isEmptyO)
        .keyboardShortcut("c", modifiers: [.command])
    }
    
    private var selectAll: some View {
        Button(
            "Select all",
            action: { mainVM?.selectAll() }
        ).keyboardShortcut("a", modifiers: [.command])
    }
    
    private var deselectAll: some View {
        Button(
            "Deselect",
            action: { mainVM?.deselectAll() }
        ).keyboardShortcut(.cancelAction)
    }
    
    private var paste: some View {
        Button(
            "Paste",
            action: vm.pasteIntoCurrentTab
        ).keyboardShortcut("v", modifiers: [.command])
    }
    
    private var pasteIntoNewTab: some View {
        Button(
            "Paste into new tab",
            action: vm.pasteIntoNewTab
        ).keyboardShortcut("v", modifiers: [.command, .shift])
    }
    
    private var newTabButton: some View {
        Button(
            "New Tab",
            action: vm.openNewTab
        ).keyboardShortcut("t", modifiers: [.command])
    }
    
    private var renameTabButton: some View {
        Button(
            "Rename Tab",
            action: renameTab
        ).keyboardShortcut("r", modifiers: [.command, .shift])
    }
    
    private var addKernelInfoButton: some View {
        SettingsLink {
            Text("Add Kernel Info")
        }
        .buttonStyle(PostButtonStyle(postAction: vm.addKernelInfo))
        .keyboardShortcut("o", modifiers: [.command, .shift])
    }

    private var openMainViewButton: some View {
        Button(
            "Main view",
            action: vm.openMainView
        ).keyboardShortcut("m", modifiers: [.command, .shift])
    }
    
    private var openDiffViewButton: some View {
        Button(
            "Diff view",
            action: vm.openDiffView
        ).keyboardShortcut("d", modifiers: [.command, .shift])
    }
    
    private var aboutAppButton: some View {
        Button(
            "About JustTags",
            action: showAboutApp
        ).onAppear {
            // Hack to pass openURL to AppVM
            self.vm.onOpenWindow = self.openWindow
        }
    }
    
    private func renameTab() {
        let textField = NSTextField(
            frame: .init(origin: .zero, size: .init(width: 200.0, height: 20.0))
        )
        textField.placeholderString = "Tab name"
        textField.stringValue = tabName.getOrEmpty()
        let alert = NSAlert()
        alert.messageText = "Enter custom name for this tab"
        let okButton = alert.addButton(withTitle: "OK")
        okButton.tag = 999
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational
        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField
        if alert.runModal().rawValue == okButton.tag, textField.stringValue.isEmpty == false {
            tabName = textField.stringValue
        }
    }
    
    private var whatsNewButton: some View {
        Button(
            "What's New in JustTags",
            action: vm.showWhatsNew
        )
    }
    
    private var releaseNotesButton: some View {
        Button(
            "Release Notes",
            action: openReleaseNotes
        )
    }
    
    private var keyBindingsButton: some View {
        SettingsLink {
            Text("Key Bindings")
        }.buttonStyle(PostButtonStyle(postAction: vm.openKeyBindings))
    }
    
    @ViewBuilder
    private func commandView(for command: Command) -> some View {
        Group {
            switch command {
            case .about:
                aboutAppButton
            case .copySelectedTags:
                copySelectedTags
            case .paste:
                paste
            case .pasteIntoNewTab:
                pasteIntoNewTab
            case .selectAll:
                selectAll
            case .deselectAll:
                deselectAll
            case .newTabButton:
                newTabButton
            case .renameTab:
                renameTabButton
            case .openMainView:
                openMainViewButton
            case .openDiffView:
                openDiffViewButton
            case .addKernelInfo:
                addKernelInfoButton
            case .diffSelectedTags:
                diffSelectedTags
            case .whatsNew:
                whatsNewButton
            case .releaseNotes:
                releaseNotesButton
            case .keyBindings:
                keyBindingsButton
            }
        }
        .disabled(currentWindow?.commands.contains(command) == false)
    }
    
}
