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
    
    internal var selectedTags: Binding<[EMVTag]>? {
        get { self[SelectedTagsKey.self] }
        set { self[SelectedTagsKey.self] = newValue }
    }
    
    private struct SelectedTagsKey: FocusedValueKey {
        typealias Value = Binding<[EMVTag]>
    }
    
    private struct WindowTypeKey: FocusedValueKey {
        typealias Value = WindowType
    }
    
}
