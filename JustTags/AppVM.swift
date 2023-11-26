//
//  AppViewModel.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 05/06/2022.
//

import SwiftUI
import SwiftyEMVTags
import Combine

internal final class AppVM: NSObject, ObservableObject {

    @Published internal var setUpInProgress: Bool = true
    @Published internal var tagDecoder: TagDecoder!
    @Published internal var kernelInfoRepo: KernelInfoRepo!
    @Published internal var tagMappingRepo: TagMappingRepo!
    
    private(set) var diffVMs: [DiffVM] = []
    private(set) var mainVMs: [MainVM] = []

    internal var windows: [NSWindow] = []
    internal var viewModels = [Int: AnyWindowVM]()
    internal var activeVM: AnyWindowVM!
    @Published internal var selectedTab: SettingsView.Tab = .kernels
    
    fileprivate var loadedState: AppState?
    
    internal var onOpenWindow: OpenWindowAction?
    internal var currentWindow: WindowType?
    
    private override init() {
        super.init()

        let loadedState = AppState.loadState()
        self.loadedState = loadedState
        if loadedState.isStateRestored {
            self.setUpInProgress = false
        }
        
        self.tagDecoder = try? TagDecoder.defaultDecoder()
        self.kernelInfoRepo = .init(handler: tagDecoder)
        try? self.kernelInfoRepo.loadSavedResources()
        
        self.tagMappingRepo = .init(handler: tagDecoder.tagMapper)
        try? self.tagMappingRepo.loadSavedResources()
        
        // Get notified when app is about to quit
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { notification in
            self.saveAppState()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: nil
        ) { notification in
            // Need to do this in this notification, otherwise it is too late
            if let w = notification.object as? NSWindow {
                w.tabbingMode = .preferred
                w.isRestorable = false
                w.disableSnapshotRestoration()
            }
        }
    }
    
    internal func addWindow(_ window: NSWindow, diffVM: DiffVM) {
        addWindow(window, viewModel: diffVM)
    }
    
    internal func addWindow(_ window: NSWindow, mainVM: MainVM) {
        addWindow(window, viewModel: mainVM)
    }
    
    internal func addWindow(_ window: NSWindow, viewModel: AnyWindowVM) {
        window.delegate = self
        window.tabbingMode = .preferred
        window.isRestorable = false
        window.disableSnapshotRestoration()
        windows.append(window)
        viewModels[window.windowNumber] = viewModel
        
        // Window is already key and active, but we just became its delegate.
        // Need to update our internal state to reflect that
        setAsActive(window: window)
    }
    
    private func didRestoreState() {
        setUpInProgress = false
        loadedState = nil
        activeMainVM?.presentingWhatsNew = shouldShowWhatsNew
    }
    
    fileprivate func setAsActive(window: NSWindow) {
        guard let vm = viewModels[window.windowNumber] else {
            assertionFailure("Unable to find a VM for window \(window.windowNumber)")
            return
        }
        activeVM = vm
    }
    
    internal func openNewTab() {
        guard let currentWindow else { return }
        
        if currentWindow == .diff {
            onOpenWindow?(id: WindowType.diff.id, value: createNewDiffVM().id)
        } else if currentWindow == .main {
            onOpenWindow?(id: WindowType.main.id)
        }
    }
    
    internal func pasteIntoNewTab() {
        let newVM = createNewMainVM()
        NSPasteboard.string.map(newVM.parse(string:))
        onOpenWindow?(id: WindowType.main.id, value: newVM.id)
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
        string.map(viewModel.parse(string:))
    }
    
    internal func deselectAll() {
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
        
        let vm: DiffVM
        
        if let emptyDiffVM = emptyDiffVM {
            // An empty diff vm is available, use it
            vm = emptyDiffVM
        } else {
            // No empty diff vms available, we will get a new one
            vm = createNewDiffVM()
        }
        
        vm.diff(tags: toDiff)
        onOpenWindow?(id: WindowType.diff.id, value: vm.id)
    }
    
    private var emptyDiffVM: DiffVM? {
        diffVMs
            .filter(\.isEmpty)
            .first
    }
    
    internal func openDiffView() {
        if let last = diffVMs.last {
            onOpenWindow?(id: WindowType.diff.id, value: last.id)
        } else {
            onOpenWindow?(id: WindowType.diff.id)
        }
    }
    
    internal var activeMainVM: MainVM? {
        activeVM as? MainVM
    }
    
    internal func openMainView() {
        if let last = mainVMs.last {
            onOpenWindow?(id: WindowType.main.id, value: last.id)
        } else {
            onOpenWindow?(id: WindowType.main.id)
        }
    }
    
    internal func addKernelInfo() {
        openSettings(at: .kernels)
    }
    
    private func window(for vm: AnyWindowVM) -> NSWindow? {
        viewModels.first(where: { $0.value === vm })
            .map(\.key)
            .flatMap({ (key: Int) -> NSWindow? in
                windows.first(where: { window in window.windowNumber == key })
            })
    }
    
    internal func showWhatsNew() {
        activeMainVM?.presentingWhatsNew = true
    }
    
    internal func openKeyBindings() {
        openSettings(at: .keyBindings)
    }
    
    private func openSettings(at tab: SettingsView.Tab) {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        
        selectedTab = tab
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
            window.delegate = nil
            
            if let diffVM = viewModels[window.windowNumber] as? DiffVM {
                diffVMs.removeFirst(with: diffVM.id)
            } else if let mainVM = viewModels[window.windowNumber] as? MainVM {
                mainVMs.removeFirst(with: mainVM.id)
            }
            
            viewModels[window.windowNumber] = nil
        }
    }
    
}

extension AppVM: DiffVMProvider {
    
    subscript(vm id: DiffVM.ID) -> DiffVM? {
        diffVMs.first(where: { $0.id == id })
    }
    
    internal func createNewDiffVM() -> DiffVM {
        let newVM = DiffVM(
            appVM: self,
            tagParser: .init(tagDecoder: tagDecoder)
        )
        diffVMs.append(newVM)
        return newVM
    }
    
}

extension AppVM: MainVMProvider {
    
    subscript(vm id: MainVM.ID) -> MainVM? {
        mainVMs.first(where: { $0.id == id })
    }
    
    internal func createNewMainVM() -> MainVM {
        // Create new main VM and add it to the list
        let newVM = MainVM(
            appVM: self,
            tagParser: .init(tagDecoder: tagDecoder)
        )
        mainVMs.append(newVM)
        
        // Restore main VM state if needed
        if setUpInProgress,
           let nextMainState = self.loadedState?.nextMainState() {
            // Restore saved state
            newVM.title = nextMainState.title
            newVM.parse(string: nextMainState.tagsHexString)
            
            if self.loadedState?.isStateRestored ?? true {
                // If no more state left to restore - finish set up
                onMain {
                    // Has to be async to avoid updating view state from rendering
                    self.setUpInProgress = false
                }
            } else {
                // If there is state left to restore - open a new main tab after a small delay
                onMain(seconds: 0.1) {
                    guard self.loadedState != nil else { return }
                    self.onOpenWindow?(id: WindowType.main.id)
                }
            }
        }
        
        return newVM
    }
    
}

extension AppVM {
    
    private static var tabCounter: Int = 0
    
    internal static var tabName: String {
        tabCounter += 1
        return "New Tab #\(tabCounter - 1)"
    }
    
}

extension AppVM {
    
    internal static let shared: AppVM = .init()
    
}
