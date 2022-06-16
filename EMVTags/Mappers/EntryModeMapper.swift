//
//  EntryModeMapper.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 16/06/2022.
//

import Foundation

let entryModeMapping: Dictionary<String, String> = [
    "00": "Unknown",
    "01": "Manual",
    "02": "Magnetic stripe",
    "03": "Bar code",
    "04": "OCR",
    "05": "Integrated circuit card (ICC). CVV can be checked.",
    "07": "Auto entry via contactless EMV.",
    "80": "Fallback to Magnetic Stripe",
    "90": "Magnetic stripe as read from track 2. CVV can be checked.",
    "91": "Auto entry via contactless magnetic stripe",
    "95": "Integrated circuit card (ICC). CVV may not be checked.",
    "99": "Same as original transaction."
]
