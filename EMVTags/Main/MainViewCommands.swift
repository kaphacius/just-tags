//
//  MainViewCommands.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 05/06/2022.
//

import SwiftUI

internal struct MainViewCommands: Commands {
    
    @Environment(\.openURL) var openURL
    @EnvironmentObject var infoDataSource: EMVTagInfoDataSource
    
    @ObservedObject internal var viewModel: AppVM
    
    var body: some Commands {
        fileCommands
        editCommands
    }
    
    @CommandsBuilder
    var editCommands: some Commands {
        CommandGroup(replacing: CommandGroupPlacement.pasteboard) {
            copySelectedTagsButton
        }
    }
    
    @CommandsBuilder
    var fileCommands: some Commands {
        CommandGroup(replacing: CommandGroupPlacement.newItem, addition: {
            newTabButton
            openTagInfoButton
            openMainViewButton
            openDiffViewButton
        })
    }
    
    private var copySelectedTagsButton: some View {
        Button(action: {
            viewModel.activeVM
                .map(\.hexString)
                .map(NSPasteboard.copyString(_:))
        }, label: {
            copyTagsButtonLabel
        })
        .keyboardShortcut("c", modifiers: [.command])
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
        Button(action: {
            if let currentWindow = NSApp.keyWindow,
               let windowController = currentWindow.windowController {
                windowController.newWindowForTab(nil)
                if let newWindow = NSApp.keyWindow, currentWindow != newWindow {
                    currentWindow.addTabbedWindow(newWindow, ordered: .above)
                }
            }
        }, label: {
            Text("New Tab")
        }).keyboardShortcut("t", modifiers: [.command])
    }
    
    private var openTagInfoButton: some View {
        Button(action: {
            let openPanel = NSOpenPanel()
            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles = true
            openPanel.allowedContentTypes = [.json]
            guard openPanel.runModal() == .OK else { return }
            
            let data = try! Data(contentsOf: openPanel.url!)
            
            let result = try! JSONDecoder().decode(TagInfoContainer.self, from: data)
            
            infoDataSource.infoList.append(contentsOf: result.tags)
        }, label: {
            Text("Open tag info list")
        }).keyboardShortcut("o", modifiers: [.command, .shift])
    }
    
    private var openDiffViewButton: some View {
        Button(action: {
            openURL(URL(string: "emvtags://diff")!)
        }, label: {
            Text("Diff view")
        }).keyboardShortcut("d", modifiers: [.command, .shift])
    }
    
    private var openMainViewButton: some View {
        Button(action: {
            openURL(URL(string: "emvtags://main")!)
        }, label: {
            Text("Main view")
        }).keyboardShortcut("m", modifiers: [.command, .shift])
    }
    
}
