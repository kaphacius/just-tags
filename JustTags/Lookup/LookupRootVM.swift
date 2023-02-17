//
//  LookupRootVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 04/01/2023.
//

import SwiftyEMVTags
import SwiftUI
import Combine

internal final class LookupRootVM: ObservableObject {
    
    @Published internal var searchText = ""
    @Published internal var selectedKernel: KernelInfo
    @Published internal var selectedTag: TagDecodingInfo?
    @Published internal var tagListSections: [LookupKernelInfoView.Section]
    internal let kernels: [KernelInfo]
    internal let tagMappings: [UInt64: TagMapping]
    
    private var cancellables: Set<AnyCancellable> = []
    private let tagSearchComponents: [Int: PrioritySearchComponents]
    
    init(tagParser: TagParser) {
        let sortedKernels = tagParser.initialKernels.sorted { $0.id < $1.id }
        let allTagsKernel = KernelInfo.makeAllTagsKernel(with: sortedKernels)
        self.kernels = [allTagsKernel] + sortedKernels
        self.tagListSections = allTagsKernel.singleSection
        self.selectedKernel = allTagsKernel
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
    
    private func selectedKernelUpdated(_ newKernel: KernelInfo) {
        self.tagListSections = newKernel.singleSection
        
        if shouldSearch(with: searchText) {
            performSearch(searchText)
        } else {
            self.tagListSections = newKernel.singleSection
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
            performSearch(searchText)
        } else if selectedKernel.singleSection != tagListSections {
            tagListSections = selectedKernel.singleSection
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
            initial: selectedKernel.tags,
            allSearchComponents: tagSearchComponents,
            words: words
        )
        tagListSections = [
            .init(title: "Best matches", items: filtered.bestMatches),
            .init(title: "More...", items: filtered.more)
        ]
    }
    
}

fileprivate let allTags = "All Tags"

extension KernelInfo: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}

fileprivate extension KernelInfo {
    
    static func makeAllTagsKernel(with kernels: [KernelInfo]) -> KernelInfo {
        .init(
            id: allTags,
            name: allTags,
            category: .scheme,
            description: allTags,
            tags: kernels.flatMap(\.tags).sorted()
        )
    }
    
    var singleSection: [LookupKernelInfoView.Section] {
        [.init(title: nil, items: tags)]
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
