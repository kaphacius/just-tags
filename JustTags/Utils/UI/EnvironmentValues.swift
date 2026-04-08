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

internal struct BitToggleHandler: EnvironmentKey {
    static let defaultValue: ((Int, Int) -> Void)? = nil
}

internal struct CurrentByteIdx: EnvironmentKey {
    static let defaultValue: Int = 0
}

extension EnvironmentValues {

    internal var isLibrary: Bool {
        get { self[IsLibrary.self] }
        set { self[IsLibrary.self] = newValue }
    }

    internal var bitToggleHandler: ((Int, Int) -> Void)? {
        get { self[BitToggleHandler.self] }
        set { self[BitToggleHandler.self] = newValue }
    }

    internal var currentByteIdx: Int {
        get { self[CurrentByteIdx.self] }
        set { self[CurrentByteIdx.self] = newValue }
    }

}
