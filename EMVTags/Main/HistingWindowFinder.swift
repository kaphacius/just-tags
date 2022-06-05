//
//  HistingWindowFinder.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 05/06/2022.
//

import SwiftUI

internal struct HostingWindowFinder: NSViewRepresentable {
    
    internal var callback: (NSWindow?) -> ()
    
    internal func makeNSView(context: Self.Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { self.callback(view.window) }
        return view
    }
    
    internal func updateNSView(_ nsView: NSView, context: Context) {}
}
