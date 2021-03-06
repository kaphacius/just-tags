//
//  DiffWindowVM.swift
//  JustTags
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
    
    override var isEmpty: Bool {
        initialTags.allSatisfy(\.isEmpty)
    }
    
    internal func updateFocusedEditor(_ idx: Int?) {
        self.focusedEditorIdx = idx
    }
    
    internal func diffInitialTags() {
        guard initialTags.contains([]) == false else {
            return
        }
    
        showsDiff = true
        diffResults = Diff.diff(tags: initialTags, onlyDifferent: false)
    }
    
    private func toggleShowOnlyDifferent(_ value: Bool) {
        diffResults = Diff.diff(tags: initialTags, onlyDifferent: value)
    }
    
    override internal func parse(string: String) {
        guard let focusedEditorIdx = focusedEditorIdx else { return }
        
        let tags = tagsByParsing(string: string)
        guard tags.isEmpty == false else {
            texts[focusedEditorIdx] = ""
            return
        }
        
        apply(tags: tags, at: focusedEditorIdx)
    }
    
    internal func apply(tags: [EMVTag], at idx: Int) {
        let tags = tags.sortedTags
        
        if initialTags.count <= idx {
            initialTags.append(tags)
        } else {
            initialTags[idx] = tags
        }
        
        refreshState()
        
        diffInitialTags()
    }
    
    internal func diff(tags: TagPair) {
        refreshState()
        initialTags = [tags.lhs, tags.rhs]
        diffInitialTags()
    }
    
    override func onTagSelected(tag: EMVTag) {
        // Do nothing, we don't support tag selection in the diff view
    }
    
}
