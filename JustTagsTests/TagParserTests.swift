//
//  TagParserTests.swift
//  JustTagsTests
//

import Testing
import SwiftyEMVTags
import SwiftyBERTLV
@testable import JustTags

private let testDecoder = try! TagDecoder.defaultDecoder()

private func kernel(
    id: String,
    triggerTags: [UInt64] = [],
    exclusiveWith: [String] = []
) -> KernelInfo {
    .init(
        id: id,
        name: id,
        category: .vendor,
        description: "",
        tags: [],
        triggerTags: triggerTags,
        exclusiveWith: exclusiveWith
    )
}

private func emvTag(bytes: [UInt8]) -> EMVTag {
    testDecoder.decodeBERTLV(try! BERTLV.parse(bytes: bytes).first!)
}

struct TagParserTests {

    // MARK: - selectedCustomKernelIds

    @Test func soloKernelWithMatchingTriggerActivates() {
        let a = kernel(id: "a", triggerTags: [0x9F06])
        let tags = [emvTag(bytes: [0x9F, 0x06, 0x01, 0xAA])]

        let result = TagParser.selectedCustomKernelIds(from: tags, among: [a])

        #expect(result == ["a"])
    }

    @Test func soloKernelWithNoMatchingTagStaysInactive() {
        let a = kernel(id: "a", triggerTags: [0x9F06])
        let tags = [emvTag(bytes: [0x5A, 0x01, 0xAA])]

        let result = TagParser.selectedCustomKernelIds(from: tags, among: [a])

        #expect(result.isEmpty)
    }

    @Test func kernelWithNoTriggerTagsStaysInactiveEvenWhenTagsPresent() {
        let a = kernel(id: "a", triggerTags: [])
        let tags = [emvTag(bytes: [0x9F, 0x06, 0x01, 0xAA])]

        let result = TagParser.selectedCustomKernelIds(from: tags, among: [a])

        #expect(result.isEmpty)
    }

    @Test func exclusionGroupHighestScorerWins() {
        let a = kernel(id: "a", triggerTags: [0x9F06, 0xDF01], exclusiveWith: ["b"])
        let b = kernel(id: "b", triggerTags: [0xDF01], exclusiveWith: ["a"])
        let tags = [
            emvTag(bytes: [0x9F, 0x06, 0x01, 0xAA]),
            emvTag(bytes: [0xDF, 0x01, 0x01, 0xBB]),
        ]

        let result = TagParser.selectedCustomKernelIds(from: tags, among: [a, b])

        #expect(result == ["a"])
    }

    @Test func exclusionGroupTieWithPositiveScoresActivatesNone() {
        let a = kernel(id: "a", triggerTags: [0x9F06], exclusiveWith: ["b"])
        let b = kernel(id: "b", triggerTags: [0xDF01], exclusiveWith: ["a"])
        let tags = [
            emvTag(bytes: [0x9F, 0x06, 0x01, 0xAA]),
            emvTag(bytes: [0xDF, 0x01, 0x01, 0xBB]),
        ]

        let result = TagParser.selectedCustomKernelIds(from: tags, among: [a, b])

        #expect(result.isEmpty)
    }

    @Test func exclusionGroupZeroZeroTieActivatesNone() {
        let a = kernel(id: "a", triggerTags: [0x9F06], exclusiveWith: ["b"])
        let b = kernel(id: "b", triggerTags: [0xDF01], exclusiveWith: ["a"])
        let tags = [emvTag(bytes: [0x5A, 0x01, 0xAA])]

        let result = TagParser.selectedCustomKernelIds(from: tags, among: [a, b])

        #expect(result.isEmpty)
    }

    // MARK: - exclusionGroups

    @Test func exclusionGroupsAreSymmetricEvenWhenDeclaredOneDirectionally() {
        let a = kernel(id: "a", exclusiveWith: ["b"])
        let b = kernel(id: "b")

        let groups = TagParser.exclusionGroups(of: [a, b])

        #expect(groups.count == 1)
        #expect(Set(groups[0]) == ["a", "b"])
    }

}
