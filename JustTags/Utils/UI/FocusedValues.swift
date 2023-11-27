//
//  FocusedValues.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 02/09/2022.
//

import SwiftUI
import SwiftyEMVTags

extension FocusedValues {
    
    internal var currentWindow: WindowType? {
        get { self[WindowTypeKey.self] }
        set { self[WindowTypeKey.self] = newValue }
    }
    
    private struct WindowTypeKey: FocusedValueKey {
        typealias Value = WindowType
    }
    
}
