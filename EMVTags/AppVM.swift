//
//  AppViewModel.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 05/06/2022.
//

import SwiftUI

internal final class AppVM: NSObject, ObservableObject {
    
    @Published internal var windows = Set<NSWindow>()
    @Published internal var viewModels = [Int: WindowVM]()
    @Published internal var activeWindow: NSWindow?
    @Published internal var activeVM: WindowVM?
    
    internal func addWindow(_ window: NSWindow, viewModel: WindowVM) {
        window.delegate = self
        windows.insert(window)
        viewModels[window.windowNumber] = viewModel
        setAsActive(window: window)
    }
    
    fileprivate func setAsActive(window: NSWindow) {
        activeWindow = window
        activeVM = viewModels[window.windowNumber]
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
