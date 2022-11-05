//
//  AppViewModel.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 05/06/2022.
//

import SwiftUI
import SwiftyEMVTags

internal final class AppVM: NSObject, ObservableObject {
    
    @Published internal var windows: [NSWindow] = []
    @Published internal var viewModels = [Int: AnyWindowVM]()
    @Published internal var activeWindow: NSWindow?
    @Published internal var setUpInProgress: Bool = true
    // Throwaway to avoid optionals
    @Published internal var activeVM: AnyWindowVM = MainVM()
    @Published internal var tagDecoder: TagDecoder?
    @Environment(\.openURL) var openURL
    
    private var newVMSetup: ((AnyWindowVM) -> Void)?
    private var loadedState: AppState?
    
    internal override init() {
        super.init()

        let loadedState = AppState.loadState()
        self.loadedState = loadedState
        if loadedState.isStateRestored {
            self.setUpInProgress = false
        }
        
        self.tagDecoder = try? TagDecoder.defaultDecoder()
        try? tagDecoder.map(loadSavedKernelInfo(for:))
        
        // Get notified when app is about to quit
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { notification in
            self.saveAppState()
        }
    }
    
    internal func addWindow(_ window: NSWindow, viewModel: AnyWindowVM) {
        print("Adding a new window")

        window.delegate = self
        windows.append(window)
        viewModel.tagDecoder = tagDecoder
        viewModel.appVM = self
        viewModels[window.windowNumber] = viewModel
        
        // Window is already key and active, but we just became its delegate.
        // Need to update our internal state to reflect that
        setAsActive(window: window)
        
        if let newVMSetup = newVMSetup {
            newVMSetup(viewModel)
            self.newVMSetup = nil
        }
        
        // No need to set up the diffVM
        guard let mainVM = activeMainVM else {
            return
        }
        
        // Need to it this way because `nextMainState` is mutating
        guard let nextState = loadedState?.nextMainState(),
              let loadedState = self.loadedState else {
            print("No state to restore")
            return
        }

        print("Restoring state")
        applyLoadedState(
            nextState,
            to: mainVM,
            activeTab: loadedState.isStateRestored ? loadedState.activeTab : nil
        )
    }
    
    private func applyLoadedState(
        _ state: MainWindowState,
        to mainVM: MainVM,
        activeTab: Int?
    ) {
        mainVM.title = state.title
        mainVM.parse(string: state.tagsHexString)
        
        // If activeTab is passed - all tabs have been restored.
        // Time to select the last active tab and finish the state restoration.
        if let activeTab = activeTab {
            print("State restoration completed")
            setUpInProgress = false
            loadedState = nil
            print("Setting tab \(activeTab) as active")
            windows[activeTab].makeKeyAndOrderFront(nil)
        } else {
            // Open the next tab after a small delay
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                guard self.loadedState != nil else { return }
                print("Opening a new tab, current tabs", self.windows.count)
                self.openNewTab()
            }
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
        if activeVM.canPaste {
            paste(string: NSPasteboard.string, into: activeVM)
        } else {
            let alert = NSAlert()
            alert.messageText = "Are you sure you want to replace tags in the current tab?"
            let okButton = alert.addButton(withTitle: "Yes")
            okButton.tag = 999
            okButton.hasDestructiveAction = true
            let newTabButton = alert.addButton(withTitle: "Paste into a new tab")
            newTabButton.tag = 888
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .warning
            let result = alert.runModal().rawValue
            if result == okButton.tag {
                paste(string: NSPasteboard.string, into: activeVM)
            } else if result == newTabButton.tag {
                pasteIntoNewTab()
            }
        }
    }
    
    private func paste(string: String?, into viewModel: AnyWindowVM) {
        if let string = string {
            viewModel.parse(string: string)
        }
    }
    
    internal func selectAll() {
        activeMainVM?.selectAll()
    }
    
    internal func deselectAll() {
        activeWindow.map(doPoof(window:))
        activeMainVM?.deselectAll()
    }
    
    internal func diffSelectedTags() {
        guard let activeMainVM = activeMainVM else {
            // Don't diff tags when DiffView is active
            return
        }
        
        guard activeMainVM.selectedIds.count == 2 else {
            // Don't diff if not exactly 2 tags selected
            return
        }

        let toDiff = (lhs: [activeMainVM.selectedTags[0]], rhs: [activeMainVM.selectedTags[1]])
        
        diffTags(toDiff)
    }
    
    internal func diffTags(_ tags: TagPair) {
        let toDiff: TagPair
        
        // If two constructed tags are selected - diff the subtags
        switch (tags.lhs[0].category, tags.rhs[0].category) {
        case (.constructed(let llhs), .constructed(let rrhs)):
            toDiff = (llhs, rrhs)
        default:
            toDiff = tags
        }
        
        if let emptyDiffVM = emptyDiffVM {
            // An empty diff vm is available, use it
            emptyDiffVM.diff(tags: toDiff)
            makeKeyAndActive(vm: emptyDiffVM)
        } else {
            // No empty diff vms available, we will get a new one
            newVMSetup = { newVM in
                guard let newVM = newVM as? DiffVM else {
                    assertionFailure("New VM is not DiffWindowVM")
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
    
    private var emptyDiffVM: DiffVM? {
        viewModels
            .values
            .filter(\.isEmpty)
            .compactMap { $0 as? DiffVM }
            .first
    }
    
    private var anyDiffWindow: NSWindow? {
        viewModels
            .first(where: { $0.value is DiffVM })
            .map(\.key)
            .flatMap({ (key: Int) -> NSWindow? in
                windows.first(where: { window in window.windowNumber == key })
            })
    }
    
    internal var activeMainVM: MainVM? {
        activeVM as? MainVM
    }
    
    internal func openDiffView() {
        if let anyDiffWindow = anyDiffWindow {
            // No need to open a new Diff window if it is already the active one
            anyDiffWindow.makeKeyAndOrderFront(self)
        } else {
            openURL(URL(string: "justtags://diff")!)
        }
    }
    
    internal func openMainView() {
        if let existingMainWindow = viewModels.first(where: { $0.value is MainVM } ),
           let window = windows.first(where: { $0.windowNumber == existingMainWindow.key }) {
            // No need to open a new Main window if it is already the active one
            window.makeKeyAndOrderFront(self)
        } else {
            openURL(URL(string: "justtags://main")!)
        }
    }
    
    internal func addKernelInfo() {
        if #available(macOS 13, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
    
    private func window(for vm: AnyWindowVM) -> NSWindow? {
        viewModels.first(where: { $0.value === vm })
            .map(\.key)
            .flatMap({ (key: Int) -> NSWindow? in
                windows.first(where: { window in window.windowNumber == key })
            })
    }
    
    private func makeKeyAndActive(vm: AnyWindowVM) {
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
        
        if let idx = windows
            .map(\.windowNumber)
            .firstIndex(of: window.windowNumber) {
            windows.remove(at: idx)
            viewModels[window.windowNumber] = nil
        }
    }
    
}

extension AppVM {
    
    private static var tabCounter: Int = 0
    
    internal static var tabName: String {
        tabCounter += 1
        return "New Tab #\(tabCounter - 1)"
    }
    
}
