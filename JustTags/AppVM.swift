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

    @Published internal var setUpInProgress: Bool = false
    @Published internal var tagDecoder: TagDecoder?
    @Published internal var kernelInfoRepo: KernelInfoRepo?
    @Published internal var tagMappingRepo: TagMappingRepo?
    @Published internal var selectedTab: SettingsView.Tab = .kernels
    
    private(set) var diffVMs: [WNS<DiffVM>] = []
    private(set) var mainVMs: [WNS<MainVM>] = []


    internal var libraryVM: LibraryVM?

    internal private(set) var loadedState: AppState
    private var vmIdToOpen: UUID?

    internal var onOpenWindow: OpenWindowAction?
    internal var currentWindow: WindowType?

    private override init() {
        self.loadedState = AppState.loadState()
        super.init()

        if loadedState.isStateRestored {
            self.setUpInProgress = false
        } else {
            self.setUpInProgress = true
        }
        
        do {
            if let decoder = try? TagDecoder.defaultDecoder() {
                self.tagDecoder = decoder
                self.kernelInfoRepo = .init(handler: decoder)
                try self.kernelInfoRepo?.loadSavedResources()
                self.tagMappingRepo = .init(handler: decoder.tagMapper)
                try self.tagMappingRepo?.loadSavedResources()
            }
        } catch {
            print(String(describing: error))
        }
        
        // Get notified when app is about to quit
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { notification in
            self.saveAppState()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let w = notification.object as? NSWindow,
                  w.title == WindowType.Case.library.title else { return }
            self?.libraryVM = nil
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: nil
        ) { notification in
            // Need to do this in this notification, otherwise it is too late
            guard let w = notification.object as? NSWindow else { return }
            
            // WWDC 2024
            // How to set tabbing mode in SwiftUI
            w.tabbingMode = .preferred
            w.isRestorable = false
            w.disableSnapshotRestoration()
        }
    }
    
    internal func openNewTab() {
        guard let currentWindow else { return }
        
        switch currentWindow.type {
        case .main:
            onOpenWindow?(id: WindowType.Case.main.id)
        case .diff:
            onOpenWindow?(id: WindowType.Case.diff.id)
        case .library:
            break
        }
    }

    internal func pasteIntoCurrentTab() {
        guard let currentWindow else { return }
        if currentWindow.canPaste {
            NSPasteboard.string.map(currentWindow.paste)
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
                NSPasteboard.string.map(currentWindow.paste)
            } else if result == newTabButton.tag {
                pasteIntoNewTab()
            }
        }
    }
    
    internal func pasteIntoNewTab() {
        switch currentWindow {
        case .main:
            let newVM = createNewMainVM()
            NSPasteboard.string.map(newVM.parse(string:))
            onOpenWindow?(id: WindowType.Case.main.id, value: newVM.id)
        case .diff:
            let newVM = createNewDiffVM()
            NSPasteboard.string.map(newVM.parse(string:))
            onOpenWindow?(id: WindowType.Case.diff.id, value: newVM.id)
        case .library:
            break
        case nil:
            break
        }
    }
    
    internal func openMainDeepLink(url: URL, openWindow: OpenWindowAction) {
        let abs = url.absoluteString
        guard let markerIdx = abs.ranges(of: /\/main\//).first else {
            return
        }
        
        let payload = String(abs.suffix(from: markerIdx.upperBound))
        let vm: MainVM
        if let latestVM = mainVMs.last.flatMap(\.value) {
            vm = latestVM
        } else {
            vm = createNewMainVM()
        }
        
        vm.parse(string: payload.removingPercentEncoding ?? payload)
        openWindow(id: WindowType.Case.main.id, value: vm.id)
    }

    internal func diffSelectedTags() {
        guard let activeMainVM = currentWindow.flatMap(\.asMainVM) else {
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
    
    private func diffTags(_ tags: TagPair) {
        let toDiff: TagPair
        
        // If two constructed tags are selected - diff the subtags
        switch (tags.lhs[0].category, tags.rhs[0].category) {
        case (.constructed(let llhs), .constructed(let rrhs)):
            toDiff = (llhs, rrhs)
        default:
            toDiff = tags
        }
        
        let vm: DiffVM
        
        if let emptyDiffVM = diffVMs.compactMap(\.value).first(where: \.isEmpty) {
            // An empty diff vm is available, use it
            vm = emptyDiffVM
        } else {
            // No empty diff vms available, we will get a new one
            vm = createNewDiffVM()
        }
        
        vm.diff(tags: toDiff)
        onOpenWindow?(id: WindowType.Case.diff.id, value: vm.id)
    }
    
    internal func openDiffView() {
        diffVMs.prune()
        if let last = diffVMs.last {
            vmIdToOpen = last.id
            onOpenWindow?(id: WindowType.Case.diff.id, value: last.id)
        } else {
            onOpenWindow?(id: WindowType.Case.diff.id)
        }
    }
    
    internal func openMainView() {
        mainVMs.prune()
        if let last = mainVMs.last {
            vmIdToOpen = last.id
            onOpenWindow?(id: WindowType.Case.main.id, value: last.id)
        } else {
            onOpenWindow?(id: WindowType.Case.main.id)
        }
    }
    
    internal func vmIdToOpen(for type: WindowType.Case) -> UUID {
        if let vmIdToOpen {
            self.vmIdToOpen = nil
            return vmIdToOpen
        } else {
            switch type {
            case .main:
                return createNewMainVM().id
            case .diff:
                return createNewDiffVM().id
            case .library:
                // We should not be here
                return .init()
            }
        }
    }
    
    internal func addKernelInfo() {
        openSettings(at: .kernels)
    }
    
    internal func showWhatsNew() {
        openMainView()
        currentWindow?.asMainVM?.presentingWhatsNew = true
    }
    
    internal func openKeyBindings() {
        openSettings(at: .keyBindings)
    }
    
    private func openSettings(at tab: SettingsView.Tab) {
        selectedTab = tab
    }
    
}

extension AppVM: DiffVMProvider {
    
    subscript(vm id: DiffVM.ID) -> DiffVM? {
        return diffVMs.first(where: { $0.id == id })
            .flatMap { $0.getWithSwap() }
    }
    
    internal func createNewDiffVM() -> DiffVM {
        // Filter existing empty or unclaimed (strong) WNSs
        diffVMs.prune()
        let newVM = DiffVM(
            appVM: self,
            tagParser: .init(tagDecoder: tagDecoder!)
        )
        diffVMs.append(.init(stongValue: newVM))

        if let nextDiffState = loadedState.nextDiffState() {
            newVM.texts = nextDiffState.texts
            newVM.reparse()
        }

        return newVM
    }

    private func openRestoredDiffWindows(completion: (() -> Void)? = nil) {
        guard loadedState.hasDiffStates else {
            completion?()
            return
        }
        let vm = createNewDiffVM()
        onOpenWindow?(id: WindowType.Case.diff.id, value: vm.id)
        onMain(seconds: 0.1) { self.openRestoredDiffWindows(completion: completion) }
    }

    private func activateRestoredWindow() {
        guard let info = loadedState.activeWindowInfo else { return }
        switch info.kind {
        case .library:
            onOpenWindow?(id: WindowType.Case.library.id)
        case .main:
            guard info.index < mainVMs.count else { return }
            onOpenWindow?(id: WindowType.Case.main.id, value: mainVMs[info.index].id)
        case .diff:
            guard info.index < diffVMs.count else { return }
            onOpenWindow?(id: WindowType.Case.diff.id, value: diffVMs[info.index].id)
        }
    }
    
}

extension AppVM: MainVMProvider {
    
    subscript(vm id: MainVM.ID) -> MainVM? {
        mainVMs.first(where: { $0.id == id })
            .flatMap { $0.getWithSwap() }
    }
    
    internal func createNewMainVM() -> MainVM {
        // Create a new MainVM and register it so AppVM can look it up by ID later.
        let newVM = MainVM(
            appVM: self,
            tagParser: .init(tagDecoder: tagDecoder!)
        )
        mainVMs.append(.init(stongValue: newVM))

        // During launch restoration, setUpInProgress is true and loadedState still has
        // unconsumed MainWindowStates. Each call to createNewMainVM() claims the next one.
        if setUpInProgress,
           let nextMainState = self.loadedState.nextMainState() {
            // Apply the saved title and tag data to the freshly created VM.
            newVM.title = nextMainState.title
            newVM.showsDetails = nextMainState.showsDetails
            newVM.parse(string: nextMainState.tagsHexString)

            if self.loadedState.isStateRestored {
                // All saved main windows are now open. Kick off the rest of the
                // restoration sequence on the next run-loop tick to avoid mutating
                // published state during a SwiftUI render pass.
                onMain {
                    self.setUpInProgress = false
                    // Open any saved diff windows, then (in the completion) open the
                    // library window if it was open at quit, and finally bring the
                    // originally-active window back to front.
                    self.openRestoredDiffWindows {
                        if self.loadedState.library != nil {
                            self.onOpenWindow?(id: WindowType.Case.library.id)
                        }
                        // Small delay lets all windows finish appearing before we
                        // activate the one that was key when the app was last quit.
                        onMain(seconds: 0.1) {
                            self.activateRestoredWindow()
                            // Show What's New only after the correct window is active.
                            self.currentWindow?.asMainVM?.presentingWhatsNew = shouldShowWhatsNew
                        }
                    }
                }
            } else {
                // More main windows still need to be created. Trigger the next one
                // after a short delay so each window has time to appear and register
                // itself before we request the one after it.
                onMain(seconds: 0.1) {
                    self.onOpenWindow?(id: WindowType.Case.main.id)
                }
            }
        } else {
            // Normal (non-restoration) path: a new blank tab was opened by the user
            // or by the app on first launch with no saved state.
            newVM.presentingWhatsNew = shouldShowWhatsNew
            // Only reopen the library during initial setup (setUpInProgress == true means
            // there were no saved main windows, so this is the very first tab on launch).
            // After restoration completes, setUpInProgress is false and we must not
            // reopen the library every time the user creates a new tab.
            if setUpInProgress, loadedState.library != nil {
                onMain {
                    self.onOpenWindow?(id: WindowType.Case.library.id)
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
