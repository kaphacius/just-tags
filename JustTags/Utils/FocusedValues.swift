//
//  FocusedValues.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 02/09/2022.
//

import SwiftUI
import SwiftyEMVTags

extension FocusedValues {
    
    internal var selectedTags: Binding<[EMVTag]>? {
        get { self[SelectedTagsKey.self] }
        set { self[SelectedTagsKey.self] = newValue }
    }
    
    internal var tabName: Binding<String>? {
        get { self[TabNameKey.self] }
        set { self[TabNameKey.self] = newValue }
    }
    
    internal var mainVM: Binding<MainVM>? {
        get { self[MainVMKey.self] }
        set { self[MainVMKey.self] = newValue }
    }
    
    private struct SelectedTagsKey: FocusedValueKey {
        typealias Value = Binding<[EMVTag]>
    }
    
    private struct TabNameKey: FocusedValueKey {
        typealias Value = Binding<String>
    }
    
    private struct MainVMKey: FocusedValueKey {
        typealias Value = Binding<MainVM>
    }
    
}
