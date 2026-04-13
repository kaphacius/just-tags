//
//  DiffVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 17/06/2022.
//

import Foundation
import SwiftyEMVTags
import Combine

internal final class DiffVM: AnyWindowVM, Identifiable {
    
    @Published internal var columns: Int
    @Published internal var texts: [String]
    @Published internal var initialTags: [[EMVTag]]
    @Published internal var diffResults: [DiffedTagPair]
    @Published internal var showOnlyDifferent: Bool
    @Published internal var showsDiff: Bool
    @Published internal var selectedColumn: Int
    
    internal let id: UUID = .init()

    private var cancellables: Set<AnyCancellable> = []
    
    internal init(
        appVM: AppVM,
        tagParser: TagParser,
        columns: Int = 2,
        texts: [String] = ["", ""],
        initialTags: [[EMVTag]] = [[], []],
        showOnlyDifferent: Bool = false,
        selectedColumn: Int = 0
    ) {
        _columns = .init(initialValue: columns)
        _texts = .init(initialValue: texts)
        _initialTags = .init(initialValue: initialTags)
        _showOnlyDifferent = .init(initialValue: showOnlyDifferent)
        _selectedColumn = .init(initialValue: selectedColumn)
        _diffResults = .init(
            initialValue: Diff.diff(
                tags: initialTags,
                onlyDifferent: false
            )
        )
        _showsDiff = .init(initialValue: initialTags.contains([]) == false)
        
        super.init()
        
        self.tagParser = tagParser
        self.appVM = appVM
        
        $showOnlyDifferent
            .sink { [weak self] newValue in
                self?.toggleShowOnlyDifferent(newValue)
            }.store(in: &cancellables)
    }
    
    var isEmpty: Bool {
        initialTags.allSatisfy(\.isEmpty)
    }
    
    internal var canPaste: Bool {
        initialTags.contains([])
    }
    
    private var shouldDiff: Bool {
        initialTags.contains([]) == false
    }
    
    internal func selectColumn(_ idx: Int) {
        guard idx >= 0, idx < columns else { return }
        self.selectedColumn = idx
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
    
    internal func parse(string: String) {
        let tags = tagsByParsing(string: string)
        guard tags.isEmpty == false else {
            return
        }
        
        texts[selectedColumn] = string
        
        apply(tags: tags, at: selectedColumn)
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
        
        if let nextEmptyColumn = initialTags.firstIndex(where: \.isEmpty) {
            selectedColumn = nextEmptyColumn
        }
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
