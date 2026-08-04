//
//  ResolvedMeaningsTests.swift
//  JustTagsTests
//

import Testing
import Foundation
import SwiftyEMVTags
import SwiftyBERTLV
@testable import JustTags

/// Registers a custom kernel that also decodes the AID tag (0x9F06, already
/// defined by the built-in `general` kernel), so decoding it yields a genuine
/// `.multipleKernels` result to resolve.
private func multipleKernelsResult() -> EMVTag.DecodingResult {
    let decoder = try! TagDecoder.defaultDecoder()
    let customKernelJSON = """
    {
      "id": "custom-aid",
      "name": "Custom AID Kernel",
      "category": "vendor",
      "description": "Test kernel",
      "tags": [
        {
          "info": {
            "tag": "9F06",
            "name": "AID",
            "description": "AID",
            "source": "card",
            "format": "binary",
            "kernel": "custom-aid",
            "minLength": "5",
            "maxLength": "16"
          }
        }
      ]
    }
    """.data(using: .utf8)!
    let customKernel = try! JSONDecoder().decode(KernelInfo.self, from: customKernelJSON)
    try! decoder.addKernelInfo(newInfo: customKernel)

    let tlv = try! BERTLV
        .parse(bytes: [0x9F, 0x06, 0x07, 0xA0, 0x00, 0x00, 0x00, 0x03, 0x10, 0x10])
        .first!
    return decoder.decodeBERTLV(tlv).decodingResult
}

struct ResolvedMeaningsTests {

    @Test func fixtureProducesGenuineConflict() {
        guard case .multipleKernels(let decodedTags) = multipleKernelsResult() else {
            Issue.record("Expected multipleKernels fixture")
            return
        }
        #expect(Set(decodedTags.map(\.kernel)) == ["custom-aid", "general"])
    }

    @Test func customBeatsBuiltIn() {
        let resolved = multipleKernelsResult().resolvedMeanings(customKernelIds: ["custom-aid"])

        #expect(resolved.primary.map(\.kernel) == ["custom-aid"])
        #expect(resolved.hidden.map(\.kernel) == ["general"])
    }

    @Test func customVsCustomTieShowsBothWithNoHidden() {
        let resolved = multipleKernelsResult()
            .resolvedMeanings(customKernelIds: ["custom-aid", "general"])

        #expect(Set(resolved.primary.map(\.kernel)) == ["custom-aid", "general"])
        #expect(resolved.hidden.isEmpty)
    }

    @Test func builtInVsBuiltInTieShowsBothWithNoHidden() {
        let resolved = multipleKernelsResult().resolvedMeanings(customKernelIds: [])

        #expect(Set(resolved.primary.map(\.kernel)) == ["custom-aid", "general"])
        #expect(resolved.hidden.isEmpty)
    }

}
