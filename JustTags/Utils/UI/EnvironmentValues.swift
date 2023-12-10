//
//  EnvironmentValue.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 14/10/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct IsLibrary: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    
    internal var isLibrary: Bool {
        get { self[IsLibrary.self] }
        set { self[IsLibrary.self] = newValue }
    }
    
}
