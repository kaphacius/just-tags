//
//  LibraryVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 04/01/2023.
//

import SwiftyEMVTags
import SwiftUI
import Combine

internal final class LibraryVM: ObservableObject {
    
    @Published internal var searchText = ""
    @Published internal var selectedKernel: KernelInfo
    @Published internal var selectedTag: TagDecodingInfo?
    @Published internal var tagListSections: [LibraryKernelInfoView.Section]
    internal let kernels: [KernelInfo]
    internal let tagMappings: [UInt64: TagMapping]
    
    private var cancellables: Set<AnyCancellable> = []
    private let tagSearchComponents: [Int: PrioritySearchComponents]
    private let generalKernel: KernelInfo
    private var initialSections: [LibraryKernelInfoView.Section]
    
    init(tagParser: TagParser) {
        let sortedKernels = tagParser.initialKernels.sorted { $0.id < $1.id }
        let allTagsKernel = KernelInfo.makeAllTagsKernel(with: sortedKernels)
        self.kernels = [allTagsKernel] + sortedKernels
        self.generalKernel = sortedKernels.first(where: { $0.id == generalKernelId })!
        self.selectedKernel = allTagsKernel
        let allTagsSections = [allTagsKernel.singleSection]
        self.tagListSections = allTagsSections
        self.initialSections = allTagsSections
        self.tagMappings = tagParser.tagMapper.mappings
        
        self.tagSearchComponents = .init(
            uniqueKeysWithValues: allTagsKernel.tags.map(\.searchPair)
        )
        
        _selectedKernel.projectedValue
            .sink(receiveValue: { [weak self] in self?.selectedKernelUpdated($0) })
            .store(in: &cancellables)
        
        self.setUpSearch()
    }
    
    // This is for previews
    convenience init(tagParser: TagParser, selectedTagIdx: Int) {
        self.init(tagParser: tagParser)
        self.selectedTag = self.tagListSections[0].items[selectedTagIdx]
    }
    
    // Sections without applying any search
    private func initialSections(for kernel: KernelInfo) -> [LibraryKernelInfoView.Section] {
        if kernel.needsGeneralKernelTags {
            // Combine selected kernel and general tags
            return [kernel.singleSection, generalKernel.singleSection]
        } else {
            return [kernel.singleSection]
        }
    }
    
    private func selectedKernelUpdated(_ newKernel: KernelInfo) {
        self.tagListSections = initialSections(for: newKernel)
        self.initialSections = tagListSections
        
        if shouldSearch(with: searchText) {
            // Filter tags if searchText is present
            performSearch(searchText)
        }
    }
    
    private func setUpSearch() {
        _searchText.projectedValue
            .debounce(for: 0.10, scheduler: RunLoop.main, options: nil)
            .removeDuplicates()
            .eraseToAnyPublisher()
            .map(\.localizedLowercase)
            .sink { [weak self] in self?.searchTags($0) }
            .store(in: &cancellables)
    }
    
    private func searchTags(_ searchText: String) {
        if shouldSearch(with: searchText) {
            // Search tags if the searchText is valid
            performSearch(searchText)
        } else if initialSections != tagListSections {
            // If current sections do not match initialSections,
            // we are coming back from searched state
            // Reset sections to initial values
            tagListSections = initialSections
            selectedTag = nil
        }
    }
    
    private func shouldSearch(with searchText: String) -> Bool {
        if searchText.count > 2 {
            return true
        } else if searchText.count == 2 && UInt64(searchText, radix: 16) != nil {
            return true
        } else {
            return false
        }
    }
    
    private func performSearch(_ searchText: String) {
        let words = Set(
            searchText
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .whitespaces))
            .filter { $0.count > 1 }
        let filtered = filterPrioritySearchable(
            initial: initialSections.flatMap(\.items),
            allSearchComponents: tagSearchComponents,
            words: words
        )
        tagListSections = [
            .init(title: "Best matches", items: filtered.bestMatches),
            .init(title: "More...", items: filtered.more)
        ]
        
        selectSingleResultIfNeeded()
    }
    
    private func selectSingleResultIfNeeded() {
        if let bestMatches = tagListSections.first,
           let bestMatch = bestMatches.items.first,
           bestMatches.items.count == 1,
           tagListSections.count == 2,
           let moreMatches = tagListSections.last,
           moreMatches.items.count == 0 {
            selectedTag = bestMatch
        }
    }
    
}

fileprivate let allTags = "All Tags"
fileprivate let allTagsKernelId = "All tags"
fileprivate let generalKernelId = "general"

extension KernelInfo: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}

fileprivate extension KernelInfo {
    
    static func makeAllTagsKernel(with kernels: [KernelInfo]) -> KernelInfo {
        .init(
            id: allTagsKernelId,
            name: allTags,
            category: .scheme,
            description: allTags,
            tags: kernels.flatMap(\.tags).sorted()
        )
    }
    
    var needsGeneralKernelTags: Bool {
        self.id != generalKernelId && self.id != allTagsKernelId
    }
    
    var singleSection: LibraryKernelInfoView.Section {
        .init(title: id, items: tags)
    }
    
}

internal extension TagDecodingInfo {
    
    var tagDetailsVM: TagDetailsVM {
        let bytes = bytes
            .map { try? EMVTag.DecodedByte(byte: 0x00, info: $0) }
            .enumerated()
            .compactMap(t2FlatMap(_:))
            .map { $0.1.decodedByteVM(idx: $0.0) }
        
        return .init(
            tag: info.tag.hexString,
            name: info.name,
            info: info.tagInfoVM,
            bytes: bytes,
            kernel: info.kernel
        )
        
    }
    
}
