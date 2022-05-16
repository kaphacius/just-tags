//
//  EMVTagsApp.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 20/03/2022.
//

import SwiftUI
import SwiftyEMVTags

@main
internal struct EMVTagsApp: App {
    
    @StateObject private var infoDataSource: EMVTagInfoDataSource
    @Environment(\.openURL) var openURL
    
    internal var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(infoDataSource)
                .handlesExternalEvents(preferring: ["main"], allowing: ["main"])
        }
        .handlesExternalEvents(matching: ["main"])
        .commands(content: commands)
        
        WindowGroup("Diff") {
            DiffView()
                .environmentObject(infoDataSource)
                .handlesExternalEvents(preferring: ["diff"], allowing: ["diff"])
        }.handlesExternalEvents(matching: ["diff"])
    }
    
    @CommandsBuilder
    private func commands() -> some Commands {
        CommandGroup(before: CommandGroupPlacement.newItem, addition: {
            newTabButton
            openTagInfoButton
            openMainViewButton
            openDiffViewButton
        })
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
            
            print(result.tags.count)
            
            infoDataSource.infoList.append(contentsOf: result.tags)
        }, label: {
            Text("New Tab")
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
    
    internal init() {
        let commonTags: Array<EMVTag.Info>
        
        if let url = Bundle.main.path(forResource: "common_tags", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: url)),
           let decoded = try? JSONDecoder().decode(TagInfoContainer.self, from: data) {
            commonTags = decoded.tags
        } else {
            commonTags = []
        }
        
        self._infoDataSource = .init(wrappedValue: .init(infoList: commonTags))
    }
}

final class EMVTagInfoDataSource: AnyEMVTagInfoSource, ObservableObject {
    
    @Published internal var infoList: Array<EMVTag.Info> = []
    
    internal init(infoList: [EMVTag.Info]) {
        self.infoList = infoList
    }
    
    func info(for tag: UInt64, kernel: EMVTag.Kernel) -> EMVTag.Info {
        infoList.first(
            where: { $0.tag == tag &&
                $0.kernel.matches(kernel)
            }
        ) ?? .unknown(tag: tag)
    }
    
}
