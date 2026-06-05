//
//  WindowVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 18/05/2022.
//

import Foundation
import SwiftyEMVTags
import SwiftyBERTLV
import SwiftUI
import Combine

protocol MainVMProvider: ObservableObject {
    
    subscript(vm id: MainVM.ID) -> MainVM? { get }
    
}

internal final class MainVM: AnyWindowVM, Identifiable {
    
    @Published internal var initialTags: [EMVTag] = []
    @Published internal var tagSearchComponents: Dictionary<EMVTag.ID, Set<String>> = [:]
    @Published internal var searchText: String = ""
    @Published internal var selectedTags = [EMVTag]()
    @Published internal var selectedIds = Set<EMVTag.ID>()
    @Published internal var expandedConstructedTags: Set<EMVTag.ID> = []
    @Published internal var showsDetails: Bool = true
    @Published internal var detailTag: EMVTag? = nil
    @Published internal var presentingWhatsNew: Bool = false
    @Published internal var didChange: Bool = false
    @Published internal var editedTags: [EMVTag.ID: [UInt8]] = [:]
    
    internal var showsTags: Bool {
        initialTags.isEmpty == false
    }
    
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
    
    var isEmpty: Bool {
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
        editedTags = [:]
    }
    
    internal override func reparse() {
        initialTags = tagParser.updateDecodingResults(for: initialTags)
        
        populateSearch()
        
        detailTag = detailTag
            .map(\.id)
            .flatMap(initialTags.first(with:))
    }
    
    internal func parse(string: String) {
        refreshState()
        initialTags = tagsByParsing(string: string)
        populateSearch()
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
    
    internal func clearWindow() {
        initialTags.removeAll()
        refreshState()
        searchText = ""
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
    
    internal func removeTag(with id: EMVTag.ID) {
        guard let updatedTags = removingTag(id: id, from: initialTags) else { return }
        initialTags = updatedTags
        populateSearch()
        editedTags.removeValue(forKey: id)
        expandedConstructedTags.remove(id)
        if detailTag?.id == id { detailTag = nil }
        if selectedIds.contains(id) {
            selectedIds.remove(id)
            selectedTags.removeFirst(with: id)
        }
    }

    private func removingTag(id: EMVTag.ID, from tags: [EMVTag]) -> [EMVTag]? {
        if tags.contains(where: { $0.id == id }) {
            return tags.filter { $0.id != id }
        }
        for (idx, tag) in tags.enumerated() {
            guard case .constructed(let subtags) = tag.category,
                  subtags.first(with: id) != nil else { continue }
            let updatedSubtags = removingTag(id: id, from: subtags) ?? subtags
            let newBERT = BERTLV(
                tag: tag.tag.tag,
                value: updatedSubtags.flatMap(\.tag.bytes),
                category: .constructed(subtags: updatedSubtags.map(\.tag))
            )
            var result = tags
            result[idx] = EMVTag(id: tag.id, tag: newBERT, category: .constructed(subtags: updatedSubtags), decodingResult: tag.decodingResult)
            return result
        }
        return nil
    }

    internal func selectMappingValue(_ hexValue: String, for tagId: EMVTag.ID) {
        guard let valueBytes = [UInt8](hexString: hexValue) else { return }
        updateTagValue(valueBytes, for: tagId)
    }

    internal func setAsciiValue(_ string: String, for tagId: EMVTag.ID) {
        updateTagValue(Array(string.utf8), for: tagId)
    }

    private func updateTagValue(_ newValueBytes: [UInt8], for tagId: EMVTag.ID) {
        guard let tag = initialTags.first(with: tagId) else { return }

        let newBERTLV = BERTLV(tag: tag.tag.tag, value: newValueBytes, category: .plain)
        guard let parsed = try? InputParser.parse(input: newBERTLV.bytes.hexString),
              let parsedFirst = parsed.first else { return }

        let decoded = tagParser.decodeBERTLV(parsedFirst)
        let newTag = EMVTag(id: tag.id, tag: decoded.tag, category: decoded.category, decodingResult: decoded.decodingResult)

        if editedTags[tag.id] == nil {
            editedTags[tag.id] = tag.tag.value
        }
        if newTag.tag.value == editedTags[tag.id] {
            editedTags.removeValue(forKey: tag.id)
        }
        initialTags = replacingTag(newTag, in: initialTags)
        if detailTag?.id == tag.id {
            detailTag = newTag
        }
    }

    internal func addTag(tagHex: String, valueHex: String) {
        guard let newTag = makeTag(tagHex: tagHex, valueHex: valueHex) else { return }
        initialTags.append(newTag)
        populateSearch()
        onDetailTagSelected(id: newTag.id)
    }

    internal func addSubtag(tagHex: String, valueHex: String, toId parentId: EMVTag.ID) {
        guard let newSubtag = makeTag(tagHex: tagHex, valueHex: valueHex),
              let updatedTags = addingSubtag(newSubtag, to: parentId, in: initialTags) else { return }
        initialTags = updatedTags
        populateSearch()
        expandedConstructedTags.insert(parentId)
        onDetailTagSelected(id: newSubtag.id)
    }

    private func addingSubtag(
        _ newSubtag: EMVTag,
        to parentId: EMVTag.ID,
        in tags: [EMVTag]
    ) -> [EMVTag]? {
        for (idx, tag) in tags.enumerated() {
            if tag.id == parentId, case .constructed(let existingSubtags) = tag.category {
                let allSubtags = existingSubtags + [newSubtag]
                let newBERT = BERTLV(tag: tag.tag.tag, value: allSubtags.flatMap(\.tag.bytes), category: .constructed(subtags: allSubtags.map(\.tag)))
                var result = tags
                result[idx] = EMVTag(id: tag.id, tag: newBERT, category: .constructed(subtags: allSubtags), decodingResult: tag.decodingResult)
                return result
            }
            if case .constructed(let subtags) = tag.category,
               let updatedSubtags = addingSubtag(newSubtag, to: parentId, in: subtags) {
                let newBERT = BERTLV(tag: tag.tag.tag, value: updatedSubtags.flatMap(\.tag.bytes), category: .constructed(subtags: updatedSubtags.map(\.tag)))
                var result = tags
                result[idx] = EMVTag(id: tag.id, tag: newBERT, category: .constructed(subtags: updatedSubtags), decodingResult: tag.decodingResult)
                return result
            }
        }
        return nil
    }

    private func replacingTag(_ newTag: EMVTag, in tags: [EMVTag]) -> [EMVTag] {
        tags.map { tag in
            if tag.id == newTag.id { return newTag }
            guard case .constructed(let subtags) = tag.category,
                  subtags.first(with: newTag.id) != nil else { return tag }
            let updatedSubtags = replacingTag(newTag, in: subtags)
            let newBERT = BERTLV(tag: tag.tag.tag, value: updatedSubtags.flatMap(\.tag.bytes), category: .constructed(subtags: updatedSubtags.map(\.tag)))
            return EMVTag(id: tag.id, tag: newBERT, category: .constructed(subtags: updatedSubtags), decodingResult: tag.decodingResult)
        }
    }

    private func makeTag(tagHex: String, valueHex: String) -> EMVTag? {
        guard let tagBytes = [UInt8](hexString: tagHex), tagBytes.isEmpty == false else { return nil }
        guard let valueBytes = [UInt8](hexString: valueHex), valueBytes.isEmpty == false else { return nil }
        let tagCode = tagBytes.reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        let bertlv = BERTLV(tag: tagCode, value: valueBytes, category: .plain)
        guard let parsed = try? InputParser.parse(input: bertlv.bytes.hexString),
              let parsedFirst = parsed.first else { return nil }
        let decoded = tagParser.decodeBERTLV(parsedFirst)
        return EMVTag(id: UUID(), tag: decoded.tag, category: decoded.category, decodingResult: decoded.decodingResult)
    }

    internal func toggleBit(byteIdx: Int, bitPosition: Int) {
        guard let tag = detailTag else { return }
        toggleBit(byteIdx: byteIdx, bitPosition: bitPosition, for: tag.id)
    }

    internal func toggleBit(byteIdx: Int, bitPosition: Int, for tagId: EMVTag.ID) {
        guard let tag = initialTags.first(with: tagId) else { return }
        let bitShift = UInt8.bitWidth - 1 - bitPosition
        var valueBytes = tag.tag.value
        guard byteIdx < valueBytes.count else { return }
        if editedTags[tag.id] == nil {
            editedTags[tag.id] = valueBytes
        }
        valueBytes[byteIdx] ^= (1 << bitShift)
        let syntheticHex = tag.tag.tag.hexString + tag.tag.lengthBytes.hexString + valueBytes.hexString
        guard let bertlvs = try? InputParser.parse(input: syntheticHex),
              let bertlv = bertlvs.first else { return }
        let decoded = tagParser.decodeBERTLV(bertlv)
        let newTag = EMVTag(id: tag.id, tag: decoded.tag, category: decoded.category, decodingResult: decoded.decodingResult)
        initialTags = replacingTag(newTag, in: initialTags)
        if valueBytes == editedTags[tag.id] {
            editedTags.removeValue(forKey: tag.id)
        }
        if detailTag?.id == tag.id {
            detailTag = newTag
        }
    }

}
