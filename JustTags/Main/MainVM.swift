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
    @Published internal var currentTags: [EMVTag] = [] {
        didSet {
            currentTagVMs = currentTags.map(TagRowVM.init(tag:))
        }
    }
    @Published internal var currentTagVMs: [TagRowVM] = []
    @Published internal var tagSearchComponents: Dictionary<EMVTag.ID, Set<String>> = [:]
    @Published internal var searchText: String = ""
    @Published internal var showingTags: Bool = false
    @Published internal var selectedTags = [EMVTag]()
    @Published internal var selectedIds = Set<EMVTag.ID>()
    @Published internal var expandedConstructedTags: Set<EMVTag.ID> = []
    @Published internal var showsDetails: Bool = true
    @Published internal var detailTag: EMVTag? = nil
    @Published var presentingWhatsNew: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var pastedString: String?
    
    override init() {
        super.init()
        setUpSearch()
    }
    
    internal func isTagSelected(id: EMVTag.ID) -> Bool {
        selectedIds.contains(id)
    }
    
    internal var hexString: String {
        selectedTags.map(\.fullHexString).joined()
    }
    
    internal func onTagSelected(id: EMVTag.ID) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
            selectedTags
                .removeFirst(with: id)
        } else {
            selectedIds.insert(id)
            currentTags
                .first(with: id)
                .map { selectedTags.append($0) }
        }
    }
    
    internal func onDetailTagSelected(id: EMVTag.ID) {
        guard let tag = currentTags.first(with: id) else {
            return
        }
        
        if detailTag == tag {
            detailTag = nil
        } else {
            detailTag = tag
        }
        showsDetails = true
    }
    
    override var isEmpty: Bool {
        initialTags.isEmpty
    }
    
    override var canPaste: Bool {
        initialTags.isEmpty
    }
    
    private func setUpSearch() {
        $searchText
            .debounce(for: 0.10, scheduler: RunLoop.main, options: nil)
            .removeDuplicates()
            .sink { [weak self] v in self?.searchTags() }
            .store(in: &cancellables)
    }
    
    internal override func refreshState() {
        super.refreshState()
        selectedTags = []
        selectedIds = []
        detailTag = nil
        expandedConstructedTags = []
    }
    
    internal override func reparse() {
        initialTags = tagParser.updateDecodingResults(for: initialTags)
        currentTags = tagParser.updateDecodingResults(for: currentTags)
        
        populateSearch()
        showingTags = initialTags.isEmpty == false
        
        detailTag = detailTag
            .map(\.id)
            .flatMap(currentTags.first(with:))
    }
    
    internal override func parse(string: String) {
        pastedString = string
        refreshState()
        initialTags = tagsByParsing(string: string)
        currentTags = initialTags
        populateSearch()
        showingTags = initialTags.isEmpty == false
    }
    
    private func populateSearch() {
        tagSearchComponents = .init(
            uniqueKeysWithValues: initialTags.flatMap(\.searchPairs)
        )
    }
    
    private func searchTags() {
        if searchText.count < 2 {
            currentTags = initialTags
            collapseAll()
        } else {
            let searchText = searchText.lowercased().toFlattenedSearchComponents
            currentTags = filterNestedSearchable(
                initial: initialTags,
                components: tagSearchComponents,
                words: Set(searchText)
            )
            expandAll()
        }
    }
    
    internal func selectAll() {
        selectedTags = currentTags
        selectedIds = Set(selectedTags.map(\.id))
    }
    
    internal func deselectAll() {
        selectedTags = []
        selectedIds = []
    }
    
    internal func diffSelectedTags() {
        if selectedTags.count < 2 {
            showNotEnoughDiffAlert()
        } else if selectedTags.count > 2 {
            showTooManyDiffAlert()
        } else {
            appVM?.diffTags(([selectedTags[0]], [selectedTags[1]]))
        }
    }
    
    internal func collapseAll() {
        expandedConstructedTags.removeAll()
    }
    
    internal func expandAll() {
        expandedConstructedTags = Set(
            currentTags
            .flatMap(\.constructedIds)
        )
    }
    
    internal func toggleShowsDetails() {
        showsDetails.toggle()
        if showsDetails == false {
            detailTag = nil
        }
    }
    
    internal func expandedBinding(for id: EMVTag.ID) -> Binding<Bool> {
        .init(
            get: { self.expandedConstructedTags.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    self.expandedConstructedTags.insert(id)
                } else {
                    self.expandedConstructedTags.remove(id)
                }
            }
        )
    }
    
}
