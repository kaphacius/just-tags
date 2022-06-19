//
//  MainViewCommands.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 05/06/2022.
//

import SwiftUI

internal struct MainViewCommands: Commands {
    
    @Environment(\.openURL) private  var openURL
    
    @ObservedObject internal var viewModel: AppVM
    
    internal var body: some Commands {
        fileCommands
        editCommands
        diffCommands
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
            openTagInfoButton
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
            action: viewModel.diffSelectedTags
        ).keyboardShortcut("d", modifiers: [.option, .shift])
    }
    
    private var copySelectedTags: some View {
        Button(action: {
            viewModel.activeVM
                .map(\.hexString)
                .map(NSPasteboard.copyString(_:))
        }, label: {
            copyTagsButtonLabel
        })
        .keyboardShortcut("c", modifiers: [.command])
    }
    
    private var selectAll: some View {
        Button(
            "Select all",
            action: viewModel.selectAll
        ).keyboardShortcut("a", modifiers: [.command])
    }
    
    private var deselectAll: some View {
        Button(
            "Deselect",
            action: viewModel.deselectAll
        ).keyboardShortcut("a", modifiers: [.command, .shift])
    }
    
    private var paste: some View {
        Button(
            "Paste",
            action: viewModel.pasteIntoCurrentTab
        ).keyboardShortcut("v", modifiers: [.command])
    }
    
    private var pasteIntoNewTab: some View {
        Button(
            "Paste into new tab",
            action: viewModel.pasteIntoNewTab
        ).keyboardShortcut("v", modifiers: [.command, .shift])
    }
    
    @ViewBuilder
    private var copyTagsButtonLabel: some View {
        if viewModel.activeVM.map(\.selectedTags.count) == 1 {
            Text("Copy selected tag")
        } else {
            Text("Copy selected tags")
        }
    }
    
    private var newTabButton: some View {
        Button(
            "New Tab",
            action: viewModel.openNewTab
        ).keyboardShortcut("t", modifiers: [.command])
    }
    
    private var openTagInfoButton: some View {
        Button(
            "Open tag info list",
            action: viewModel.loadInfoJSON
        ).keyboardShortcut("o", modifiers: [.command, .shift])
    }
    
    private var openDiffViewButton: some View {
        Button(
            "Diff view",
            action: viewModel.openDiffView
        ).keyboardShortcut("d", modifiers: [.command, .shift])
    }
    
    private var openMainViewButton: some View {
        Button(
            "Main view",
            action: viewModel.openMainView
        ).keyboardShortcut("m", modifiers: [.command, .shift])
    }
    
}
