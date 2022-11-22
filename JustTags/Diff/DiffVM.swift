//
//  DiffVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 17/06/2022.
//

import Foundation
import SwiftyEMVTags
import Combine

internal final class DiffVM: AnyWindowVM {
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
        diffResults: [TagDiffResult] = [],
        showOnlyDifferent: Bool = false
    ) {
        _columns = .init(initialValue: columns)
        _texts = .init(initialValue: texts)
        _initialTags = .init(initialValue: initialTags)
        _showOnlyDifferent = .init(initialValue: showOnlyDifferent)
        _diffResults = .init(
            initialValue: Diff.diff(
                tags: initialTags,
                onlyDifferent: false
            )
        )
        _showsDiff = .init(initialValue: initialTags.contains([]) == false)
        
        super.init()
        
        $showOnlyDifferent
            .sink { [weak self] newValue in
                self?.toggleShowOnlyDifferent(newValue)
            }.store(in: &cancellables)
    }
    
    override var isEmpty: Bool {
        initialTags.allSatisfy(\.isEmpty)
    }
    
    private var shouldDiff: Bool {
        initialTags.contains([]) == false
    }
    
    internal func updateFocusedEditor(_ idx: Int?) {
        self.focusedEditorIdx = idx
    }
    
    internal func diffInitialTags() {
        guard shouldDiff else { return }

        showsDiff = true
        diffResults = Diff.diff(tags: initialTags, onlyDifferent: showOnlyDifferent)
    }
    
    private func toggleShowOnlyDifferent(_ value: Bool) {
        guard shouldDiff else { return }
        diffResults = Diff.diff(tags: initialTags, onlyDifferent: value)
    }
    
    override func reparse() {
        // TODO: reparse both left and right side
        texts.enumerated().forEach { (offset, string) in
            guard string.isEmpty == false else { return }
            
            let tags = tagsByParsing(string: string)
            guard tags.isEmpty == false else {
                texts[offset] = ""
                return
            }
            
            apply(tags: tags, at: offset)
        }
    }
    
    override internal func parse(string: String) {
        guard let focusedEditorIdx = focusedEditorIdx else { return }
        
        let tags = tagsByParsing(string: string)
        guard tags.isEmpty == false else {
            texts[focusedEditorIdx] = ""
            return
        }
        
        texts[focusedEditorIdx] = string
        
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
    
    internal func flipSides() {
        let newZero = (texts[1], initialTags[1])
        let newOne = (texts[0], initialTags[0])
        texts = [newZero.0, newOne.0]
        initialTags = [newZero.1, newOne.1]
        toggleShowOnlyDifferent(showOnlyDifferent)
    }
    
}
