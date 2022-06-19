//
//  DiffWindowVM.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 17/06/2022.
//

import Foundation
import SwiftyEMVTags
import Combine

internal final class DiffWindowVM: AnyWindowVM {
    @Published internal var columns: Int
    @Published internal var texts: [String]
    @Published internal var initialTags: [[EMVTag]]
    @Published internal var diffResults: [DiffedTagPair]
    @Published internal var showOnlyDifferent: Bool
    @Published internal var showsDiff: Bool
    
    private var focusedEditorIdx: Int?
    
    private var cancellables: Set<AnyCancellable> = []
    
    internal init(
        columns: Int = 2,
        texts: [String] = ["", ""],
        initialTags: [[EMVTag]] = [[], []],
        diffResults: [TagDiffResult] = []
    ) {
        _columns = .init(initialValue: columns)
        _texts = .init(initialValue: texts)
        _initialTags = .init(initialValue: initialTags)
        _showOnlyDifferent = .init(initialValue: false)
        _diffResults = .init(
            initialValue: Diff.diff(
                tags: initialTags,
                onlyDifferent: false
            )
        )
        _showsDiff = .init(initialValue: initialTags.contains([]) == false)
        
        super.init()
        
        $showOnlyDifferent
            .sink(receiveValue: toggleShowOnlyDifferent)
            .store(in: &cancellables)
    }
    
    internal func updateFocusedEditor(_ idx: Int?) {
        self.focusedEditorIdx = idx
    }
    
    internal func diffTags() {
        guard initialTags.contains([]) == false else {
            return
        }
    
        showsDiff = true
        toggleShowOnlyDifferent(showOnlyDifferent)
    }
    
    private func toggleShowOnlyDifferent(_ value: Bool) {
        diffResults = Diff.diff(tags: initialTags, onlyDifferent: value)
    }
    
    override func parse(string: String) {
        guard let focusedEditorIdx = focusedEditorIdx else { return }
        
        do {
            try parseInput(string, at: focusedEditorIdx)
        } catch {
            texts[focusedEditorIdx] = ""
            showsAlert = true
        }
    }
    
    internal func parseInput(_ input: String, at idx: Int) throws {
        guard let infoDataSource = infoDataSource else {
            assertionFailure("infoDataSource is missing")
            return
        }
        
        let tlv = try InputParser.parse(input: input)
        let tags = tlv
            .map { EMVTag(tlv: $0, kernel: .general, infoSource: infoDataSource) }
            .sortedTags
        
        guard tags.isEmpty == false else { return }
        
        if initialTags.count <= idx {
            initialTags.append(tags)
        } else {
            initialTags[idx] = tags
        }
        
        refreshState()
        
        diffTags()
    }
    
    override func onTagSelected(tag: EMVTag) {
        // Do nothing, we don't support tag selection in the diff view
    }
    
}
