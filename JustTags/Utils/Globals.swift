//
//  Globals.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 30/04/2022.
//

import SwiftUI

internal let diffBackground: Color = .blue.opacity(0.3)

internal func doPoof(window: NSWindow) {
    let loc = CGPoint(x: window.frame.maxX - 15, y: window.frame.maxY - 70)
    let poofSize = 20.0
    
    NSAnimationEffect.poof
        .show(centeredAt: loc, size: .init(width: poofSize, height: poofSize))
}
