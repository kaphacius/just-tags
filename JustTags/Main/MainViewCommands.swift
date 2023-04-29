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
    @Environment(\.openURL) private var openURL
    
    @ObservedObject internal var vm: AppVM
    
    private func onOpenUrl(url: URL) {
        openURL(url)
    }
    
    internal var body: some Commands {
        aboutCommands
        fileCommands
        editCommands
        diffCommands
        helpCommands
    }
    
    @CommandsBuilder
    private var aboutCommands: some Commands {
        CommandGroup(replacing: .appInfo) {
            aboutAppButton
                .onAppear {
                    // Hack to pass openURL to AppVM
                    self.vm.onOpenUrl = self.onOpenUrl(url:)
                }
        }
    }
    
    @CommandsBuilder
    private var editCommands: some Commands {
        CommandGroup(replacing: .pasteboard) {
            copySelectedTags
            paste
            pasteIntoNewTab
            selectAll
            deselectAll
        }
        CommandGroup(replacing: .undoRedo) {}
    }
    
    private var fileCommands: some Commands {
        CommandGroup(replacing: .newItem) {
            newTabButton
            renameTabButton
            openMainViewButton
            openDiffViewButton
            openTagLibraryButton
            addKernelInfoButton
        }
    }
    
    private var diffCommands: some Commands {
        CommandMenu("Diff") {
            diffSelectedTags
        }
    }
    
    private var helpCommands: some Commands {
        CommandGroup(replacing: .help) {
            whatsNewButton
            releaseNotesButton
            keyBindingsButton
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
        Button(
            "Add custom kernel info",
            action: vm.addKernelInfo
        ).keyboardShortcut("o", modifiers: [.command, .shift])
    }
    
    private var openDiffViewButton: some View {
        Button(
            "Diff view",
            action: vm.openDiffView
        ).keyboardShortcut("d", modifiers: [.command, .shift])
    }
    
    private var openMainViewButton: some View {
        Button(
            "Main view",
            action: vm.openMainView
        ).keyboardShortcut("m", modifiers: [.command, .shift])
    }
    
    private var aboutAppButton: some View {
        Button(
            "About JustTags",
            action: showAboutApp
        )
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
        Button(
            "Key Bindings",
            action: vm.openKeyBindings
        )
    }
    
    private var openTagLibraryButton: some View {
        Button(
            "Tag Library",
            action: vm.openTagLibrary
        ).keyboardShortcut("l", modifiers: [.command, .shift])
    }
    
}
