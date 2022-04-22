//
//  InputParser.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 21/04/2022.
//

import Foundation
import SwiftyBERTLV

struct InputParser {
    
    enum Error: LocalizedError {
        case failedToParseInput
    }
    
    static func parse(input: String) throws -> [BERTLV] {
        var parsedData: Data? = nil
        
        let hexStringBytes = input
            .replacingOccurrences(of: " ", with: "")
            .split(by: 2)
            .map { UInt8($0, radix: 16) }
        
        let compactedHexStringBytes = hexStringBytes.compactMap { $0 }
        
        if hexStringBytes.count == compactedHexStringBytes.count {
            parsedData = Data(compactedHexStringBytes)
        } else if let base64Bytes = Data(
            base64Encoded: input, options: .ignoreUnknownCharacters
        ) {
            parsedData = Data(base64Bytes)
        }
        
        guard let parsedData = parsedData else {
            throw Error.failedToParseInput
        }
        
        return try BERTLV.parse(bytes: [UInt8](parsedData))
    }
    
}
