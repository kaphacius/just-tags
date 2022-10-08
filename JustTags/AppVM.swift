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
    @Published internal var tagDecoder: TagDecoder? = try? TagDecoder.defaultDecoder()
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
        
        // Get notified when app is about to quit
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { notification in
            self.saveAppState()
        }
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
//            self.paste(string: "9F02060000000017779F2608BE57A8A40B7E8FEB5F24032802294F08A0000000041010019F0607A000000004101082025980500A4D43454E4742524742509F120D6D6320656E20676272206762705F3401219F3602000C9F0702FFC09F080200029F34031F03028F01FA9F2701808E0C000000000000000042031F038408A0000000041010019F0D05CC000000009F0E0500000000009F0F05CC000000009F101A0110A0420FA40000000000000000000000FF00000000000000FF9F7E01019F3901079F33032008089F1A0205289F1C0839393939393939399F1D082C288000000000009F350121950500000080015F2A0209789A032210079F4104000000029F21031046349C01009F3704B176A290DFBF025CFFFF03313F04D8CE000000036CCA0F5D8CBD5BC3F1A5270D3E172C6D86564C0CB1960E8033A59173D1AF8C6DE1774CB9440019C45409A855180991C6F13C36D6EB39CBA4F888FBCE8BD104CB3C9CB04C399D42C7D0F16AE46218BA64C20104C30102C5020200E10B9F33030828C85F2A020978", into: self.activeVM)
//            self.paste(string: "E03B5F2A0208405F3601029F150241219F1A0208409F1C0839393939393939399F1E0839393939393939399F33036028C89F3501219F40056000B0A001E181FCDF810C01039F0607A00000000310109F150241219F160F3530202020202020202020202020209F1A0208409F1C0839393939393939399F090200969F33036028489F3501219F40056000B0A001DFC30D0400000000DFC30C04000F423FDFC30E04000009C49F660432004000DFC30A0101E7209F5A053102682620DFC3050400000000DFC3040400000000DFC30604000009C4E7239F5A083102682612000003DFC3050400000000DFC3040400000000DFC30604000009C4E7209F5A053102682612DFC3050400000000DFC3040400000000DFC30604000009C4E7209F5A053102682600DFC3050400000000DFC3040400000000DFC30604000009C4E181FCDF810C01039F0607A00000000320109F150241219F160F3530202020202020202020202020209F1A0208409F1C0839393939393939399F090200969F33036028489F3501219F40056000B0A001DFC30D0400000000DFC30C04000F423FDFC30E04000009C49F660432004000DFC30A0101E7209F5A053102682620DFC3050400000000DFC3040400000000DFC30604000009C4E7239F5A083102682612000003DFC3050400000000DFC3040400000000DFC30604000009C4E7209F5A053102682612DFC3050400000000DFC3040400000000DFC30604000009C4E7209F5A053102682600DFC3050400000000DFC3040400000000DFC30604000009C4E181FCDF810C01039F0607A00000000320209F150241219F160F3530202020202020202020202020209F1A0208409F1C0839393939393939399F090200969F33036028489F3501219F40056000B0A001DFC30D0400000000DFC30C04000F423FDFC30E04000009C49F660432004000DFC30A0101E7209F5A053102682620DFC3050400000000DFC3040400000000DFC30604000009C4E7239F5A083102682612000003DFC3050400000000DFC3040400000000DFC30604000009C4E7209F5A053102682612DFC3050400000000DFC3040400000000DFC30604000009C4E7209F5A053102682600DFC3050400000000DFC3040400000000DFC30604000009C4E181CCDF810C01029F0607A00000000410109F150241219F160F3530202020202020202020202020209F1A0208409F1C0839393939393939399F090200029F3501219F40056000B0A001DF812005FC50BCA000DF8121050010000000DF812205FC50BCF8009F1D086C7A0000000000009F6D02FFFFDF81170160DF81180120DF81190108DF811B0130DF811E0110DF811F0108DF812306000000000000DF812406000000999999DF812506000000999999DF8126060000000050009F530152DF811C020078DF811D0102DF812C0100E181C7DF810C01029F060AA0000000041010D076129F150241219F160F3530202020202020202020202020209F1A0208409F1C0839393939393939399F090200029F3501219F40056000B0A001DF812005FC50BCA000DF8121050010000000DF812205FC50BCF8009F1D009F6D02FFFFDF81170120DF81180120DF81190108DF811B01B0DF811E0110DF811F0108DF812306000000000000DF812406000000999999DF812506000000999999DF8126060000000050009F530152DF811C020078DF811D0102DF812C0100E181C7DF810C01029F060AA0000000041010D076139F150241219F160F3530202020202020202020202020209F1A0208409F1C0839393939393939399F090200029F3501219F40056000B0A001DF812005FC50BCA000DF8121050010000000DF812205FC50BCF8009F1D009F6D02FFFFDF81170120DF81180120DF81190108DF811B01B0DF811E0110DF811F0108DF812306000000000000DF812406000000999999DF812506000000999999DF8126060000000050009F530152DF811C020078DF811D0102DF812C0100E181CCDF810C01029F0607A00000000422039F150241219F160F3530202020202020202020202020209F1A0208409F1C0839393939393939399F090200029F3501219F40056000B0A001DF812005FC50BCA000DF8121050010000000DF812205FC50BCF8009F1D08485A8000000000009F6D02FFFFDF81170120DF81180100DF81190108DF811B0190DF811E0100DF811F0108DF812306000000000000DF812406000000999999DF812506000000999999DF8126060000000050009F530152DF811C020078DF811D0102DF812C0100E181CCDF810C01029F0607A00000000430609F150241219F160F3530202020202020202020202020209F1A0208409F1C0839393939393939399F090200029F3501219F40056000B0A001DF812005FC50BCA000DF8121050010800000DF812205FC50BCF8009F1D084C528000000000009F6D02FFFFDF81170120DF81180100DF81190108DF811B01B0DF811E0100DF811F0108DF812306000000000000DF812406000000999999DF812506000000999999DF8126060000000050009F530152DF811C020078DF811D0102DF812C0100E1818FDF810C01049F0606A000000025019F150241219F160F3530202020202020202020202020209F1A0208409F1C0839393939393939399F090200019F33036028C89F3501219F40056000B0A001DFC30D0400000000DFC30C04000F423FDFC30E0400004E209F6D01C09F6E04D8A00000DFC30A0100DF812005FC50B8A000DF8121050010000000DF812205FE50B8F800E181FCDF810C01039F0607A00000009808409F150241219F160F3530202020202020202020202020209F1A0208409F1C0839393939393939399F090200969F33036028489F3501219F40056000B0A001DFC30D0400000000DFC30C04000F423FDFC30E04000013889F660432004000DFC30A0101E7209F5A053102682620DFC3050400000000DFC3040400000000DFC3060400001388E7239F5A083102682612000003DFC3050400000000DFC3040400000000DFC3060400001388E7209F5A053102682612DFC3050400000000DFC3040400000000DFC3060400001388E7209F5A053102682600DFC3050400000000DFC3040400000000DFC3060400001388", into: self.activeVM)
//        }
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
//        let toDiff: TagPair
//        
//        // If two constructed tags are selected - diff the subtags
//        if tags.lhs[0].isConstructed && tags.rhs[0].isConstructed {
//            toDiff = (tags.lhs[0].subtags, tags.rhs[0].subtags)
//        } else {
//            toDiff = tags
//        }
//        
//        if let emptyDiffVM = emptyDiffVM {
//            // An empty diff vm is available, use it
//            emptyDiffVM.diff(tags: toDiff)
//            makeKeyAndActive(vm: emptyDiffVM)
//        } else {
//            // No empty diff vms available, we will get a new one
//            newVMSetup = { newVM in
//                guard let newVM = newVM as? DiffVM else {
//                    assertionFailure("New VM is not DiffWindowVM")
//                    return
//                }
//                newVM.diff(tags: toDiff)
//            }
//            openDiffView()
//            // If the diff window was already in place - open
//            if anyDiffWindow != nil {
//                openNewTab()
//            }
//        }
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
    
    internal func loadInfoJSON() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.json]
        guard openPanel.runModal() == .OK else { return }
        
        let data = try! Data(contentsOf: openPanel.url!)
        
        try! tagDecoder?.addKernelInfo(data: data)
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
