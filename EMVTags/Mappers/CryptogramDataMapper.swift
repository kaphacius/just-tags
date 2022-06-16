//
//  ApplicationCryptogramMapper.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 16/06/2022.
//

import Foundation

let cryptogramDataMapping: Dictionary<String, String> = [
    "80": "ARQC, Authorisation Request Cryptogram",
    "40": "TC, Transaction Certificate",
    "00": "AAC, Application Authentication Cryptogram"
]
