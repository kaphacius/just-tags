//
//  InputParser.swift
//  JustTags
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
        var parsedData: [UInt8]? = nil
        
        let hexStringBytes = input
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .split(by: 2)
            .map { UInt8($0, radix: 16) }
        
        let compactedHexStringBytes = hexStringBytes.compactMap { $0 }
        
        if hexStringBytes.count == compactedHexStringBytes.count {
            // Attempt parsing a hex string
            parsedData = compactedHexStringBytes
        } else if let base64Bytes = parseBase64(input: input) {
            parsedData = base64Bytes
        }
        
        guard let parsedData = parsedData else {
            throw Error.failedToParseInput
        }
        
        return try BERTLV.parse(bytes: [UInt8](parsedData))
    }
    
    static private func parseBase64(input: String) -> [UInt8]? {
        // Attempt parsing a base64 string
        if let base64Bytes = Data(
            base64Encoded: input, options: .ignoreUnknownCharacters
        ) {
            return [UInt8](base64Bytes)
        }
        
        // Attempt parsing a base64 string with missing padding
        // Base64 data is encoded with groups of 4 characters
        let groupSize = 4
        
        // Check if the last group might be missing padding
        let lastGroupSize = input.count % groupSize
        
        // Only 2 and 3 characters in the last group are allowed
        guard lastGroupSize == 2 || lastGroupSize == 3 else { return nil }
        
        let paddedInput = input.appending(String(repeating: "=", count: groupSize - lastGroupSize))
        
        if let base64Bytes = Data(
            base64Encoded: paddedInput, options: .ignoreUnknownCharacters
        ) {
            // Attempt parsing a base64 string
            return [UInt8](base64Bytes)
        }
        
        return nil
    }
    
}
