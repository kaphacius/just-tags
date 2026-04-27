//
//  AppStateTests.swift
//  JustTagsTests
//

import Testing
import Foundation
@testable import JustTags

struct AppStateTests {

    // MARK: - Round-trip

    @Test func roundTrip() throws {
        let state = AppState(
            mains: [.init(title: "Tab 1", tagsHexString: "9F330368 08C8", showsDetails: false)],
            diffs: [.init(texts: ["aabb", "ccdd"])],
            library: nil,
            activeWindowInfo: .main(0)
        )
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(AppState.self, from: data)

        var mutableDecoded = decoded
        let mainState = mutableDecoded.nextMainState()
        #expect(mainState?.title == "Tab 1")
        #expect(mainState?.tagsHexString == "9F330368 08C8")
        #expect(mainState?.showsDetails == false)

        let diffState = mutableDecoded.nextDiffState()
        #expect(diffState?.texts == ["aabb", "ccdd"])

        #expect(decoded.activeWindowInfo?.kind == .main)
        #expect(decoded.activeWindowInfo?.index == 0)
    }

    // MARK: - Backward compatibility

    @Test func decodesOldStateWithoutDiffs() throws {
        let json = """
        {"mains":[{"title":"Tab 1","tagsHexString":"9F330368 08C8"}]}
        """
        var state = try JSONDecoder().decode(AppState.self, from: Data(json.utf8))
        #expect(state.nextMainState()?.showsDetails == true)
        #expect(state.nextDiffState() == nil)
        #expect(state.hasDiffStates == false)
        #expect(state.activeWindowInfo == nil)
    }

    @Test func decodesOldStateWithoutActiveWindowInfo() throws {
        let json = """
        {"mains":[{"title":"Tab 1","tagsHexString":"9F330368 08C8"}],"diffs":[]}
        """
        let state = try JSONDecoder().decode(AppState.self, from: Data(json.utf8))
        #expect(state.activeWindowInfo == nil)
    }

    // MARK: - State consumption

    @Test func nextMainStateConsumesInOrder() throws {
        let json = """
        {"mains":[{"title":"First","tagsHexString":""},{"title":"Second","tagsHexString":""}],"diffs":[]}
        """
        var state = try JSONDecoder().decode(AppState.self, from: Data(json.utf8))
        #expect(state.nextMainState()?.title == "First")
        #expect(state.nextMainState()?.title == "Second")
        #expect(state.nextMainState() == nil)
    }

    @Test func isStateRestoredAfterConsumingAllMains() throws {
        let json = """
        {"mains":[{"title":"Tab","tagsHexString":""}],"diffs":[]}
        """
        var state = try JSONDecoder().decode(AppState.self, from: Data(json.utf8))
        #expect(state.isStateRestored == false)
        _ = state.nextMainState()
        #expect(state.isStateRestored)
    }

    @Test func emptyStateIsAlreadyRestored() {
        #expect(AppState.empty.isStateRestored)
    }

}
