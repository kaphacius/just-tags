//
//  AlphabeticFormatter.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 14/06/2022.
//

import Foundation
import SwiftyEMVTags

let mappers: Dictionary<UInt64, Dictionary<String, String>> = [
    0x9F15: mccMapping,
    0x5F2A: currencyCodeMapping,
    0x9F06: aidMapping,
    0x9F1A: countryCodeMapping,
    0x84: aidMapping,
    0x4F: aidMapping,
    0x9F39: entryModeMapping,
    0x9F27: cryptogramDataMapping,
    0x9F35: terminalTypeMapping
]

extension EMVTag {
    
    var textRepresentation: String? {
        if format.hasPrefix("a") {
            return String(bytes: value, encoding: .ascii)
        } else {
            return mappers[tag]?[value.hexString]
        }
    }
    
}
