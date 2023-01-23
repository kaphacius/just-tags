//
//  EnvironmentValue.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 14/10/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct SelectedTag: EnvironmentKey {
    static let defaultValue: Binding<EMVTag?> = .constant(nil)
}

internal struct IsLookup: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    internal var selectedTag: Binding<EMVTag?> {
        get { self[SelectedTag.self] }
        set { self[SelectedTag.self] = newValue }
    }
    
    internal var isLookup: Bool {
        get { self[IsLookup.self] }
        set { self[IsLookup.self] = newValue }
    }
}
