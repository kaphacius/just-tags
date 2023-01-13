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
    @Published internal var selectedKernel: String
    @Published internal var title: String
    @Published internal var selectedTag: TagDecodingInfo?
    @Published internal var tagList: [TagDecodingInfo]
    internal var kernelRows: [String] { kernels.map(\.id) }
    
    private let tagParser: TagParser
    private let kernels: [KernelInfo]
    private var cancellables: Set<AnyCancellable> = []
    
    init(tagParser: TagParser) {
        let sortedKernels = tagParser.initialKernels.sorted { $0.id < $1.id }
        let allTagsKernel = KernelInfo.makeAllTagsKernel(with: sortedKernels)
        self.kernels = [allTagsKernel] + sortedKernels
        self.tagList = allTagsKernel.tags
        self.selectedKernel = allTagsKernel.id
        self.title = allTagsKernel.id
        self.tagParser = tagParser
        
        _selectedKernel.projectedValue
            .sink(receiveValue: { [weak self] in self?.selectedKernelUpdated($0) })
            .store(in: &cancellables)
        
        self.setUpSearch()
    }
    
    // This is for previews
    convenience init(tagParser: TagParser, selectedTagIdx: Int) {
        self.init(tagParser: tagParser)
        self.selectedTag = self.tagList[selectedTagIdx]
    }
    
    private func selectedKernelUpdated(_ newKernel: String) {
        if let idx = kernels.firstIndex(where: { $0.id == newKernel }) {
            // 0 is for All Tags
            self.tagList = kernels[idx].tags
            self.title = kernels[idx].name
        }
    }
    
    internal func detailVM(for tag: TagDecodingInfo) -> TagDetailsVM {
        let bytes = tag
            .bytes.map { try? EMVTag.DecodedByte(byte: 0x00, info: $0) }
            .enumerated()
            .compactMap { pair in
                if let element = pair.element {
                    return (element: element, offset: pair.offset)
                } else {
                    return nil
                }
            }
            .map { $0.element.decodedByteVM(idx: $0.offset) }

        let vm: TagDetailsVM = .init(
            tag: tag.info.tag.hexString,
            name: tag.info.name,
            info: tag.info.tagInfoVM,
            bytes: bytes,
            kernel: tag.info.kernel
        )

        return vm
    }
    
    private func setUpSearch() {
        _searchText.projectedValue
            .debounce(for: 0.10, scheduler: RunLoop.main, options: nil)
            .removeDuplicates()
            .eraseToAnyPublisher()
            .sink { [weak self] in self?.searchTags($0) }
            .store(in: &cancellables)
    }
    
    private func searchTags(_ searchText: String) {
        if searchText.count < 2 {
            selectedKernelUpdated(self.selectedKernel)
        } else if searchText.count == 2 && UInt64(searchText, radix: 16) != nil {
            performSearch(searchText)
        } else {
            performSearch(searchText)
        }
    }
    
    private func performSearch(_ searchText: String) {
        let sstr = searchText.lowercased()
        selectedKernel = allTags
        selectedKernelUpdated(self.selectedKernel)
        tagList = kernels[0].tags.filter {
            $0.info.searchComponents.joined()
                .appending($0.info.tag.hexString)
                .lowercased()
                .contains(sstr)
        }
    }
    
}

fileprivate let allTags = "All Tags"

extension TagDecodingInfo: Comparable {
    
    public static func < (lhs: TagDecodingInfo, rhs: TagDecodingInfo) -> Bool {
        lhs.info.tag < rhs.info.tag
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
    
}
