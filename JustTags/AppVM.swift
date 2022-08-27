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
    // Throwaway to avoid optionals
    @Published internal var activeVM: AnyWindowVM = MainWindowVM()
    @Published internal var infoDataSource: EMVTagInfoDataSource = .init(infoList: [])
    @Environment(\.openURL) var openURL
    
    private var newVMSetup: ((AnyWindowVM) -> Void)?
    private var loadedState: AppState?
    
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
        self.loadedState = AppState.loadState()
        
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
        viewModel.infoDataSource = infoDataSource
        viewModel.appVM = self
        viewModels[window.windowNumber] = viewModel
        
        // Window is already key and active, but we just became its delegate.
        // Need to update our internal state to reflect that
        setAsActive(window: window)
        
        if let newVMSetup = newVMSetup {
            newVMSetup(viewModel)
            self.newVMSetup = nil
        }
        
        // Need to it this way because `nextMainState` is mutating
        guard let nextState = loadedState?.nextMainState(),
              let loadedState = self.loadedState,
              let mainVM = viewModel as? MainWindowVM else {
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
        to mainVM: MainWindowVM,
        activeTab: Int?
    ) {
        mainVM.title = state.title
        mainVM.parse(string: state.tagsHexString)
        
        // If activeTab is passed - all tabs have been restored.
        // Time to select the last active tab and finish the state restoration.
        if let activeTab = activeTab {
            print("State restoration completed")
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
        activeVM.selectAll()
    }
    
    internal func deselectAll() {
        if activeVM.selectedIds.isEmpty == false {
            activeWindow.map(doPoof(window:))
        }
    
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
            makeKeyAndActive(vm: emptyDiffVMKV)
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
            openURL(URL(string: "justtags://diff")!)
        }
    }
    
    internal func openMainView() {
        if let existingDiffWindow = viewModels.first(where: { $0.value is MainWindowVM } ),
           let window = windows.first(where: { $0.windowNumber == existingDiffWindow.key }) {
            // No need to open a new Main window if it is already the active one
            window.makeKeyAndOrderFront(self)
        } else {
            openURL(URL(string: "justtags://main")!)
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
    
    private func makeKeyAndActive(vm: AnyWindowVM) {
        window(for: vm)
            .map { $0.makeKeyAndOrderFront(self) }
    }
    
    private func doPoof(window: NSWindow) {
        let loc = CGPoint(x: window.frame.maxX - 15, y: window.frame.maxY - 45)
        let poofSize = 20.0
        
        NSAnimationEffect.poof
            .show(centeredAt: loc, size: .init(width: poofSize, height: poofSize))
    }
    
    internal func showAboutApp() {
        NSApplication.shared.orderFrontStandardAboutPanel(
            options: [
                .credits: creditsString,
                .init(rawValue: "Copyright"): "© 2022 YURII ZADOIANCHUK"
            ]
        )
    }
    
    private var creditsString: NSAttributedString {
        let creditsString = NSMutableAttributedString(
            string: "This is a handy app to help you with (almost) all your EMV tag needs.\nClick "
        )
        
        let bug = NSMutableAttributedString(
            string: "here",
            attributes: [.link: "https://github.com/kaphacius/just-tags/issues/new?labels=bug&title=A+minor+bug"]
        )
        creditsString.append(bug)
        
        creditsString.append(.init(string: " if you have spotted a bug, or "))
        
        let enhancement = NSMutableAttributedString(
            string: "here",
            attributes: [.link: "https://github.com/kaphacius/just-tags/issues/new?labels=enhancement&title=A+great+idea"]
        )
        creditsString.append(enhancement)
        
        creditsString.append(.init(string: " if you have a suggestion."))
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineHeightMultiple = 1.3
        
        let totalRange = NSRange(location: 0, length: creditsString.length)
        let font = NSFont.preferredFont(forTextStyle: .body)
        
        creditsString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: totalRange
        )
        
        creditsString.addAttribute(
            .font,
            value: font,
            range: totalRange
        )
        
        return creditsString
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
