//
//  InputParserTests.swift
//  JustTagsTests
//

import Testing
import SwiftyBERTLV
@testable import JustTags

struct InputParserTests {

    // MARK: - Hex parsing

    @Test func parsesPlainHex() throws {
        let result = try InputParser.parse(input: "9F330368 08C8")
        #expect(result.count == 1)
        #expect(result[0].value == [0x68, 0x08, 0xC8])
    }

    @Test func parsesHexWithSpaces() throws {
        let result = try InputParser.parse(input: "9F 33 03 68 08 C8")
        #expect(result.count == 1)
        #expect(result[0].value == [0x68, 0x08, 0xC8])
    }

    @Test func parsesHexWithNewlines() throws {
        let result = try InputParser.parse(input: "9F33\n03\n6808C8")
        #expect(result.count == 1)
        #expect(result[0].value == [0x68, 0x08, 0xC8])
    }

    @Test func parsesMultipleHexTags() throws {
        // 9F33 03 68 08 C8  +  9F36 02 00 01
        let result = try InputParser.parse(input: "9F330368 08C8 9F36020001")
        #expect(result.count == 2)
    }

    // MARK: - Base64 parsing

    @Test func parsesBase64() throws {
        // [0x9F, 0x33, 0x03, 0x68, 0x08, 0xC8] base64-encoded
        let result = try InputParser.parse(input: "nzMDaAjI")
        #expect(result.count == 1)
        #expect(result[0].value == [0x68, 0x08, 0xC8])
    }

    @Test func parsesBase64WithMissingPadding() throws {
        // [0x9F, 0x33, 0x01, 0xAA] = "nzMBqg==" in base64; stripped padding gives 6 chars (lastGroupSize == 2)
        let result = try InputParser.parse(input: "nzMBqg")
        #expect(result.count == 1)
        #expect(result[0].value == [0xAA])
    }

    // MARK: - Invalid input

    @Test func throwsOnIncompleteTLV() {
        // 0x9F is the first byte of a two-byte tag; the TLV is incomplete
        #expect(throws: (any Error).self) {
            try InputParser.parse(input: "9F")
        }
    }

    @Test func throwsOnUnparseableInput() {
        // Not valid hex and not valid base64
        #expect(throws: InputParser.Error.failedToParseInput) {
            try InputParser.parse(input: "---")
        }
    }

}
