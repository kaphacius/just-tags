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
    // Throwaway to avoid optionals
    @Published internal var activeVM: AnyWindowVM = MainWindowVM()
    @Published internal var infoDataSource: EMVTagInfoDataSource = .init(infoList: [])
    @Environment(\.openURL) var openURL
    
    private var newVMSetup: ((AnyWindowVM) -> Void)?
    
    internal func addWindow(_ window: NSWindow, viewModel: AnyWindowVM) {
        window.delegate = self
        windows.insert(window)
        viewModel.infoDataSource = infoDataSource
        viewModel.appVM = self
        viewModels[window.windowNumber] = viewModel
        setAsActive(window: window)
        
        if let newVMSetup = newVMSetup {
            newVMSetup(viewModel)
            self.newVMSetup = nil
        }
    }
    
    fileprivate func setAsActive(window: NSWindow) {
        guard let vm = viewModels[window.windowNumber] else {
            assertionFailure("Unable to find a VM for window \(window.windowNumber)")
            return
        }
        activeWindow = window
        activeVM = vm
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
    
    internal func pasteIntoNewTab() {
        newVMSetup = { [weak self] in
            self?.paste(string: NSPasteboard.string, into: $0)
        }
        openNewTab()
    }
    
    internal func pasteIntoCurrentTab() {
        paste(string: NSPasteboard.string, into: activeVM)
    }
    
    private func paste(string: String?, into viewModel: AnyWindowVM?) {
        t2FlatMap((string, viewModel))
            .map { $0.1.parse(string: $0.0) }
    }
    
    internal func selectAll() {
        activeVM.selectAll()
    }
    
    internal func deselectAll() {
        activeVM.deselectAll()
    }
    
    internal func diffSelectedTags() {
        guard activeVM is MainWindowVM else {
            // Don't diff tags when DiffView is active
            return
        }
        
        guard activeVM.selectedTags.count == 2 else {
            // Don't diff if not exactly 2 tags selected
            return
        }
        
        let toDiff = (lhs: [activeVM.selectedTags[0]], rhs: [activeVM.selectedTags[1]])
        
        diffTags(toDiff)
    }
    
    internal func diffTags(_ tags: TagPair) {
        let toDiff: TagPair
        
        // If two constructed tags are selected - diff the subtags
        if tags.lhs[0].isConstructed && tags.rhs[0].isConstructed {
            toDiff = (tags.lhs[0].subtags, tags.rhs[0].subtags)
        } else {
            toDiff = tags
        }
        
        if let emptyDiffVMKV = emptyDiffVMKV.map(\.value) {
            // An empty diff vm is available, use it
            emptyDiffVMKV.diff(tags: toDiff)
            makeActive(vm: emptyDiffVMKV)
        } else {
            // No empty diff vms available, we will get a new one
            newVMSetup = { newVM in
                guard let newVM = newVM as? DiffWindowVM else {
                    assertionFailure("activeVM must be set")
                    return
                }
                newVM.diff(tags: toDiff)
            }
            openDiffView()
            // If the diff window was already in place - open
            if anyDiffWindow != nil {
                openNewTab()
            }
        }
    }
    
    private var emptyDiffVMKV: (key: Int, value: DiffWindowVM)? {
        viewModels
            .filter(\.value.isEmpty)
            .first(where: { $0.value is DiffWindowVM })
            .map { ($0.key, $0.value as? DiffWindowVM )}
            .flatMap(t2FlatMap(_:))
    }
    
    private var anyDiffWindow: NSWindow? {
        viewModels
            .first(where: { $0.value is DiffWindowVM })
            .map(\.key)
            .flatMap({ (key: Int) -> NSWindow? in
                windows.first(where: { window in window.windowNumber == key })
            })
    }
    
    internal func openDiffView() {
        if let anyDiffWindow = anyDiffWindow {
            // No need to open a new Diff window if it is already the active one
            anyDiffWindow.makeKeyAndOrderFront(self)
        } else {
            openURL(URL(string: "emvtags://diff")!)
        }
    }
    
    internal func openMainView() {
        if let existingDiffWindow = viewModels.first(where: { $0.value is MainWindowVM } ),
           let window = windows.first(where: { $0.windowNumber == existingDiffWindow.key }) {
            // No need to open a new Main window if it is already the active one
            window.makeKeyAndOrderFront(self)
        } else {
            openURL(URL(string: "emvtags://main")!)
        }
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
    
    private func window(for vm: AnyWindowVM) -> NSWindow? {
        viewModels.first(where: { $0.value === vm })
            .map(\.key)
            .flatMap({ (key: Int) -> NSWindow? in
                windows.first(where: { window in window.windowNumber == key })
            })
    }
    
    private func makeActive(vm: AnyWindowVM) {
        window(for: vm)
            .map { $0.makeKeyAndOrderFront(self) }
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
        
        windows.remove(window)
        _ = viewModels.removeValue(forKey: window.windowNumber)
    }
    
}

extension AppVM {
    
    private static var tabCounter: Int = 0
    
    internal static var tabName: String {
        tabCounter += 1
        return "Unknown #\(tabCounter - 1)"
    }
    
}
