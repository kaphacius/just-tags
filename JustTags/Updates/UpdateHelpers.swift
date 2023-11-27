//
//  UpdatesHelpers.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 29/11/2022.
//

import Foundation

internal let appVersion: String? = Bundle
    .main
    .infoDictionary?["CFBundleShortVersionString"] as? String

fileprivate var didShowWhatsNew = false

var shouldShowWhatsNew: Bool {
    
    guard didShowWhatsNew == false else {
        return false
    }
    
    guard let appVersion = appVersion else {
        return false
    }
    
    let key = "didShow\(appVersion)"
    
    if UserDefaults.standard.bool(forKey: key) {
        return false
    } else {
        UserDefaults.standard.setValue(true, forKey: key)
        didShowWhatsNew = true
        return true
    }
}
