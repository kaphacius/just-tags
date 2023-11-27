//
//  Globals.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 30/04/2022.
//

import SwiftUI

internal let diffBackground: Color = .blue.opacity(0.3)

internal func openReleaseNotes() {
    NSWorkspace.shared.open(releaseNotesURL)
}

private let releaseNotesURL = URL(string: "https://github.com/kaphacius/just-tags/releases")!

internal let lookupSymbol = "x"
