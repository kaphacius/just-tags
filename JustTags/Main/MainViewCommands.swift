//
//  MainViewCommands.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 05/06/2022.
//

import SwiftUI

internal struct MainViewCommands: Commands {
    
    @Environment(\.openURL) private  var openURL
    
    @ObservedObject internal var vm: AppVM
    
    internal var body: some Commands {
        aboutCommands
        fileCommands
        editCommands
        diffCommands
    }
    
    @CommandsBuilder
    private var aboutCommands: some Commands {
        CommandGroup(replacing: .appInfo) {
            aboutAppButton
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
        }
    }
    
    private var diffCommands: some Commands {
        CommandMenu("Diff") {
            diffSelectedTags
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
            NSPasteboard.copyString(vm.activeVM.hexString)
        }, label: {
            copyTagsButtonLabel
        })
        .keyboardShortcut("c", modifiers: [.command])
    }
    
    private var selectAll: some View {
        Button(
            "Select all",
            action: vm.selectAll
        ).keyboardShortcut("a", modifiers: [.command])
    }
    
    private var deselectAll: some View {
        Button(
            "Deselect",
            action: vm.deselectAll
        ).keyboardShortcut("a", modifiers: [.command, .shift])
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
    
    @ViewBuilder
    private var copyTagsButtonLabel: some View {
        if vm.activeVM.selectedTags.count == 1 {
            Text("Copy selected tag")
        } else {
            Text("Copy selected tags")
        }
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
            action: vm.activeVM.renameTab
        ).keyboardShortcut("r", modifiers: [.command, .shift])
    }
    
    private var openTagInfoButton: some View {
        Button(
            "Open tag info list",
            action: vm.loadInfoJSON
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
    
}
