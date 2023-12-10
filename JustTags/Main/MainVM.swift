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

protocol MainVMProvider: ObservableObject {
    
    subscript(vm id: MainVM.ID) -> MainVM? { get }
    
}

internal final class MainVM: AnyWindowVM, Identifiable {
    
    @Published internal var initialTags: [EMVTag] = []
    @Published internal var tagSearchComponents: Dictionary<EMVTag.ID, Set<String>> = [:]
    @Published internal var searchText: String = ""
    @Published internal var showingTags: Bool = false
    @Published internal var selectedTags = [EMVTag]()
    @Published internal var selectedIds = Set<EMVTag.ID>()
    @Published internal var expandedConstructedTags: Set<EMVTag.ID> = []
    @Published internal var showsDetails: Bool = true
    @Published internal var detailTag: EMVTag? = nil
    @Published internal var presentingWhatsNew: Bool = false
    @Published internal var didChange: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    internal let id = UUID()
    
    internal var currentTags: [EMVTag] {
        if searchText.count < 2 {
            return initialTags
        } else {
            let words = searchText.lowercased().toFlattenedSearchComponents
            return filterNestedSearchable(
                initial: initialTags,
                components: tagSearchComponents,
                words: Set(words)
            )
        }
    }
    
    internal init(
        appVM: AppVM = .shared,
        tagParser: TagParser = .init(tagDecoder: try! .defaultDecoder())
    ) {
        super.init()
        
        self.appVM = appVM
        self.tagParser = tagParser
        
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
            initialTags
                .first(with: id)
                .map { selectedTags.append($0) }
        }
    }
    
    internal func onDetailTagSelected(id: EMVTag.ID) {
        guard let tag = initialTags.first(with: id) else {
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
    
    var canPaste: Bool {
        initialTags.isEmpty
    }
    
    private func setUpSearch() {
        $searchText
            .removeDuplicates()
            .sink { [weak self] in self?.searchTags(text: $0) }
            .store(in: &cancellables)
        
        $selectedTags
            .removeDuplicates()
            .sink { [weak self] _ in
                // Need to catch this to update the commands
                self?.didChange = true
            }.store(in: &cancellables)
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
        
        populateSearch()
        showingTags = initialTags.isEmpty == false
        
        detailTag = detailTag
            .map(\.id)
            .flatMap(initialTags.first(with:))
    }
    
    internal override func parse(string: String) {
        refreshState()
        initialTags = tagsByParsing(string: string)
        populateSearch()
        showingTags = initialTags.isEmpty == false
        selectSingleTagIfNeeded()
    }
    
    private func selectSingleTagIfNeeded() {
        // Select the tag automatically if only one was parsed and decoded
        if currentTags.count == 1,
           let first = currentTags.first,
           first.decodingResult.tagDetailsVMs.isEmpty == false {
            detailTag = first
        }
    }
    
    private func populateSearch() {
        tagSearchComponents = .init(
            uniqueKeysWithValues: initialTags.flatMap(\.searchPairs)
        )
    }
    
    private func searchTags(text: String) {
        if text.count < 2 {
            collapseAll()
        } else {
            expandAll()
            selectSingleTagIfNeeded()
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
            appVM?.diffSelectedTags()
        }
    }
    
    internal func collapseAll() {
        expandedConstructedTags.removeAll()
    }
    
    internal func expandAll() {
        expandedConstructedTags = Set(
            initialTags
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
