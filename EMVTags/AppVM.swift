//
//  AppViewModel.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 05/06/2022.
//

import SwiftUI
import SwiftyEMVTags

internal final class AppVM: NSObject, ObservableObject {
    
    @Published internal var windows = Set<NSWindow>()
    @Published internal var viewModels = [Int: AnyWindowVM]()
    @Published internal var activeWindow: NSWindow?
    @Published internal var activeVM: AnyWindowVM?
    @Published internal var infoDataSource: EMVTagInfoDataSource = .init(infoList: [])
    
    internal func addWindow(_ window: NSWindow, viewModel: AnyWindowVM) {
        window.delegate = self
        windows.insert(window)
        viewModel.infoDataSource = infoDataSource
        viewModels[window.windowNumber] = viewModel
        setAsActive(window: window)
    }
    
    fileprivate func setAsActive(window: NSWindow) {
        activeWindow = window
        activeVM = viewModels[window.windowNumber]
    }
    
    internal override init() {
        super.init()
        
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
    
    internal func openNewTab() {
        if let currentWindow = NSApp.keyWindow,
           let windowController = currentWindow.windowController {
            windowController.newWindowForTab(nil)
            if let newWindow = NSApp.keyWindow, currentWindow != newWindow {
                currentWindow.addTabbedWindow(newWindow, ordered: .above)
            }
        }
    }
    
    internal func pasteIntoCurrentTab() {
        DispatchQueue.main.async { [self] in
            guard let pasteString = NSPasteboard.general.string(forType: .string),
                  let activeVM = activeVM
            else {
                return
            }
            activeVM.parse(string: pasteString)
        }
    }
    
    internal func selectAll() {
        guard let activeVM = activeVM else {
            assertionFailure("activeVM must be set")
            return
        }

        activeVM.selectAll()
    }
    
    internal func deselectAll() {
        guard let activeVM = activeVM else {
            assertionFailure("activeVM must be set")
            return
        }
        
        activeVM.deselectAll()
    }
    
    internal func loadInfoJSON() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.json]
        guard openPanel.runModal() == .OK else { return }
        
        let data = try! Data(contentsOf: openPanel.url!)
        
        let result = try! JSONDecoder().decode(TagInfoContainer.self, from: data)
        
        infoDataSource.infoList.append(contentsOf: result.tags)
    }
    
}

extension AppVM: NSWindowDelegate {
    
    func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
            return
        }
        
        setAsActive(window: window)
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
            return
        }
        
        _ = viewModels.removeValue(forKey: window.windowNumber)
    }
    
}
