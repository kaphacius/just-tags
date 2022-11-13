//
//  PreferenceValues.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 13/11/2022.
//

import Foundation
import SwiftUI

struct AlertPreferenceKey: PreferenceKey {
    
    typealias Value = PresentableAlert?
    
    static var defaultValue: PresentableAlert?
    
    static func reduce(value: inout PresentableAlert?, nextValue: () -> PresentableAlert?) {
        value = nextValue()
    }
}
