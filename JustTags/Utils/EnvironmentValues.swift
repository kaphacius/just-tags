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

extension EnvironmentValues {
    internal var selectedTag: Binding<EMVTag?> {
        get { self[SelectedTag.self] }
        set { self[SelectedTag.self] = newValue }
    }
}
