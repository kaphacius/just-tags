//
//  WindowVM.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 18/05/2022.
//

import Foundation
import SwiftyEMVTags
import SwiftUI
import Combine

internal class AnyWindowVM: ObservableObject {
    
    internal var infoDataSource: EMVTagInfoDataSource?
    
    @Published internal var selectedTags = [EMVTag]()
    @Published internal var selectedIds = Set<UUID>()
    @Published internal var selectedTag: EMVTag? = nil
    @Published internal var showsAlert: Bool = false
    
    internal func contains(id: UUID) -> Bool {
        selectedIds.contains(id)
    }
    
    internal func onTagSelected(tag: EMVTag) {
        if selectedIds.contains(tag.id) {
            selectedIds.remove(tag.id)
            _ = selectedTags
                .firstIndex(of: tag)
                .map{ selectedTags.remove(at: $0) }
        } else {
            selectedIds.insert(tag.id)
            selectedTags.append(tag)
        }
    }
    
    internal var hexString: String {
        selectedTags.map(\.hexString).joined()
    }
    
    internal func parse(string: String) {}
    
    internal func refreshState() {
        selectedTags = []
        selectedIds = []
        selectedTag = nil
    }
    
    internal func selectAll() { }
    
    internal func deselectAll() { }
}

internal final class WindowVM: AnyWindowVM {
    
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
    
    private func setUpSearch() {
        $searchText
            .debounce(for: 0.2, scheduler: RunLoop.main, options: nil)
            .removeDuplicates()
            .sink { v in
                self.updateTags()
            }.store(in: &cancellables)
    }
    
    internal override func parse(string: String) {
        guard let infoDataSource = infoDataSource else {
            assertionFailure("infoDataSource is missing")
            return
        }
        
        do {
            let tlv = try InputParser.parse(input: string)
            
            initialTags = tlv.map { EMVTag(tlv: $0, kernel: .general, infoSource: infoDataSource) }
            
            let pairs = initialTags.flatMap { tag in
                [(tag.id, tag.searchString)] + tag.subtags.map { ($0.id, $0.searchString) }
            }
            
            currentTags = initialTags
            tagDescriptions = .init(uniqueKeysWithValues: pairs)
            showingTags = true
            refreshState()
        } catch {
            showsAlert = true
        }
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
            print(currentTags.count)
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
    
}
