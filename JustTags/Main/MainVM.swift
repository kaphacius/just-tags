//
//  WindowVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 18/05/2022.
//

import Foundation
import SwiftyEMVTags
import SwiftUI
import Combine

internal final class MainVM: AnyWindowVM {
    
    @Published internal var initialTags: [EMVTag] = []
    @Published internal var currentTags: [EMVTag] = []
    @Published internal var tagDescriptions: Dictionary<UUID, String> = [:]
    @Published internal var searchText: String = ""
    @Published internal var showingTags: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setUpSearch()
    }
    
    override var isEmpty: Bool {
        initialTags.isEmpty
    }
    
    override var canPaste: Bool {
        initialTags.isEmpty
    }
    
    private func setUpSearch() {
        $searchText
            .debounce(for: 0.2, scheduler: RunLoop.main, options: nil)
            .removeDuplicates()
            .sink { v in
                self.updateTags()
            }.store(in: &cancellables)
    }
    
    internal override func parse(string: String) {
        refreshState()
        
        initialTags = tagsByParsing(string: string)
        
        let pairs = initialTags.flatMap { tag in
            [(tag.id, tag.searchString)] + tag.subtags.map { ($0.id, $0.searchString) }
        }
        
        currentTags = initialTags
        tagDescriptions = .init(uniqueKeysWithValues: pairs)
        showingTags = initialTags.isEmpty == false
        disclosureGroups = .init(
            uniqueKeysWithValues: initialTags
                .filter(\.isConstructed)
                .map(\.id)
                .map { ($0, false) }
        )
    }
    
    private func updateTags() {
        if searchText.count < 2 {
            currentTags = initialTags
        } else {
            let searchText = searchText.lowercased()
            let matchingTags = Set(
                tagDescriptions
                    .filter { $0.value.contains(searchText) }
                    .keys
            )
            currentTags = initialTags
                .filter { matchingTags.contains($0.id) }
                .map { $0.filtered(with: searchText, matchingTags: matchingTags) }
        }
    }
    
    override internal func selectAll() {
        selectedTags = currentTags
        selectedIds = Set(selectedTags.map(\.id))
    }
    
    override internal func deselectAll() {
        selectedTags = []
        selectedIds = []
    }
    
    override internal func diffSelectedTags() {
        if selectedTags.count < 2 {
            showNotEnoughDiffAlert()
        } else if selectedTags.count > 2 {
            showTooManyDiffAlert()
        } else {
            appVM?.diffTags(([selectedTags[0]], [selectedTags[1]]))
        }
    }
    
    internal func collapseAll() {
        disclosureGroups.keys.forEach { key in
            disclosureGroups[key] = false
        }
    }
    
    internal func expandAll() {
        disclosureGroups.keys.forEach { key in
            disclosureGroups[key] = true
        }
    }
    
    internal func toggleShowsDetails() {
        showsDetails.toggle()
        if showsDetails == false {
            detailTag = nil
        }
    }
    
}
