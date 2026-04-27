//
//  DiffTests.swift
//  JustTagsTests
//

import Testing
import SwiftyEMVTags
@testable import JustTags

struct DiffTests {

    // MARK: - diffCompare (byte-level)

    @Test func equalArraysProduceAllEqual() {
        let result = diffCompare(left: [1, 2, 3], right: [1, 2, 3])
        #expect(result.lhs == [.equal, .equal, .equal])
        #expect(result.rhs == [.equal, .equal, .equal])
    }

    @Test func differentArraysProduceAllDifferent() {
        let result = diffCompare(left: [1, 2, 3], right: [4, 5, 6])
        #expect(result.lhs == [.different, .different, .different])
        #expect(result.rhs == [.different, .different, .different])
    }

    @Test func mixedArraysProduceCorrectResults() {
        let result = diffCompare(left: [1, 2, 3], right: [1, 9, 3])
        #expect(result.lhs == [.equal, .different, .equal])
        #expect(result.rhs == [.equal, .different, .equal])
    }

    @Test func leftLongerMarksExtraAsDifferent() {
        let result = diffCompare(left: [1, 2, 3], right: [1])
        #expect(result.lhs == [.equal, .different, .different])
        #expect(result.rhs == [.equal])
    }

    @Test func rightLongerMarksExtraAsDifferent() {
        let result = diffCompare(left: [1], right: [1, 2, 3])
        #expect(result.lhs == [.equal])
        #expect(result.rhs == [.equal, .different, .different])
    }

    @Test func emptyArraysProduceEmptyResults() {
        let result = diffCompare(left: [Int](), right: [Int]())
        #expect(result.lhs.isEmpty)
        #expect(result.rhs.isEmpty)
    }

    @Test func oneEmptyOneSideProducesAllDifferent() {
        let result = diffCompare(left: [1, 2], right: [Int]())
        #expect(result.lhs == [.different, .different])
        #expect(result.rhs.isEmpty)
    }

    // MARK: - Diff.diff

    @Test func singleTagListProducesAllEqual() throws {
        let tags = try makeTags(hex: "9F330368 08C8")
        let result = Diff.diff(tags: [tags], onlyDifferent: false)
        #expect(result.count == 1)
        #expect(result[0].isEqual)
    }

    @Test func emptyInputProducesEmptyResult() {
        let result = Diff.diff(tags: [], onlyDifferent: false)
        #expect(result.isEmpty)
    }

    @Test func identicalTagListsProduceAllEqual() throws {
        let tags = try makeTags(hex: "9F330368 08C8 9F36020001")
        let result = Diff.diff(tags: [tags, tags], onlyDifferent: false)
        #expect(result.allSatisfy { $0.isEqual })
    }

    @Test func onlyDifferentFilterWorks() throws {
        let lhs = try makeTags(hex: "9F330368 08C8 9F36020001")
        let rhs = try makeTags(hex: "9F330368 08C8 9F360200FF")
        let all = Diff.diff(tags: [lhs, rhs], onlyDifferent: false)
        let filtered = Diff.diff(tags: [lhs, rhs], onlyDifferent: true)
        #expect(filtered.count < all.count)
        #expect(filtered.allSatisfy { $0.isEqual == false })
    }

    // MARK: - Helpers

    private func makeTags(hex: String) throws -> [EMVTag] {
        let decoder = try TagDecoder.defaultDecoder()
        return try InputParser.parse(input: hex).map(decoder.decodeBERTLV)
    }

}
