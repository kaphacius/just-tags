//
//  AppViewModel.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 05/06/2022.
//

import SwiftUI
import SwiftyEMVTags
import Combine

internal final class AppVM: NSObject, ObservableObject, DiffVMProvider {

    @Published internal var setUpInProgress: Bool = true
    @Published internal var tagDecoder: TagDecoder!
    @Published internal var kernelInfoRepo: KernelInfoRepo!
    @Published internal var tagMappingRepo: TagMappingRepo!
    
    private var diffVMs: [DiffVM] = []

    internal var windows: [NSWindow] = []
    internal var viewModels = [Int: AnyWindowVM]()
    // Throwaway to avoid optionals
    internal var activeVM: AnyWindowVM = MainVM()
    @Published internal var selectedTab: SettingsView.Tab = .kernels
    
    private var newVMSetup: ((MainVM) -> Void)?
    private var loadedState: AppState?
    
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
        
        if let newVMSetup = newVMSetup {
            newVMSetup(mainVM)
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
            didRestoreState()
            return
        }

        print("Restoring state")
        applyLoadedState(
            nextState,
            to: mainVM,
            activeTab: loadedState.isStateRestored ? loadedState.activeTab : nil
        )
    }
    
    internal func addWindow(_ window: NSWindow, viewModel: AnyWindowVM) {
        print("Adding a new window")

        window.delegate = self
        window.tabbingMode = .preferred
        window.isRestorable = false
        window.disableSnapshotRestoration()
        windows.append(window)
        viewModel.tagParser = .init(tagDecoder: tagDecoder)
        viewModel.appVM = self
        viewModels[window.windowNumber] = viewModel
        
        // Window is already key and active, but we just became its delegate.
        // Need to update our internal state to reflect that
        setAsActive(window: window)
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
            print("Setting tab \(activeTab) as active")
            windows[activeTab].makeKeyAndOrderFront(nil)
            didRestoreState()
        } else {
            // Open the next tab after a small delay
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                guard self.loadedState != nil else { return }
                print("Opening a new tab, current tabs", self.windows.count)
                self.openNewTab()
            }
        }
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
        if let currentWindow, currentWindow == .diff {
            onOpenWindow?(id: WindowType.diff.rawValue, value: createNewDiffVM().id)
            return
        }
        
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
        onOpenWindow?(id: WindowType.diff.rawValue, value: vm.id)
    }
    
    subscript(vm id: DiffVM.ID) -> DiffVM? {
        diffVMs.first(where: { $0.id == id })
    }
    
    internal func createNewDiffVM() -> DiffVM {
        let newVM = DiffVM()
        diffVMs.append(newVM)
        return newVM
    }
    
    private var emptyDiffVM: DiffVM? {
        diffVMs
            .filter(\.isEmpty)
            .first
    }
    
    internal func openDiffView() {
        if let last = diffVMs.last {
            onOpenWindow?(id: WindowType.diff.rawValue, value: last.id)
        } else {
            onOpenWindow?(id: WindowType.diff.rawValue)
        }
    }
    
    internal var activeMainVM: MainVM? {
        activeVM as? MainVM
    }
    
    internal func openMainView() {
        if let existingMainWindow = viewModels.first(where: { $0.value is MainVM } ),
           let window = windows.first(where: { $0.windowNumber == existingMainWindow.key }) {
            // No need to open a new Main window if it is already the active one
            window.makeKeyAndOrderFront(self)
        } else {
            onOpenWindow?(id: WindowType.main.rawValue)
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
    
    private func makeKeyAndActive(vm: AnyWindowVM) {
        window(for: vm)
            .map { $0.makeKeyAndOrderFront(self) }
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
            }
            
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

extension AppVM {
    
    internal static let shared: AppVM = .init()
    
}
