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
    @Published internal var inputString = ""
    @Published internal var tagDetailVMs: [TagDetailsVM] = []
    @Published internal var autoSelectCount: Int = 0
    internal let kernels: [KernelInfo]
    internal let tagMappings: [UInt64: TagMapping]

    private var cancellables: Set<AnyCancellable> = []
    private let tagSearchComponents: [Int: PrioritySearchComponents]
    private let generalKernel: KernelInfo?
    private var initialSections: [LibraryKernelInfoView.Section]
    private let tagParser: TagParser
    private let decodableTagIds: Set<UInt64>

    init(tagParser: TagParser, initialState: LibraryWindowState? = nil) {
        self.tagParser = tagParser

        let sortedKernels = tagParser.initialKernels.sorted { $0.id < $1.id }
        let allTagsKernel = KernelInfo.makeAllTagsKernel(with: sortedKernels)
        self.kernels = [allTagsKernel] + sortedKernels
        self.generalKernel = sortedKernels.first(where: { $0.id == generalKernelId })
        self.selectedKernel = allTagsKernel
        let allTagsSections = [allTagsKernel.singleSection]
        self.tagListSections = allTagsSections
        self.initialSections = allTagsSections
        self.tagMappings = tagParser.tagMapper.mappings

        self.decodableTagIds = Set(
            tagParser.initialKernels.flatMap(\.tags)
                .filter { $0.bytes.count > 0 || tagParser.tagMapper.mappings[$0.info.tag] != nil }
                .map(\.info.tag)
        )

        self.tagSearchComponents = .init(
            uniqueKeysWithValues: allTagsKernel.tags.map(\.searchPair)
        )

        if let state = initialState {
            self.searchText = state.searchText
            self.inputString = state.inputString
            if let tagId = state.selectedTagId, let kernelId = state.selectedKernelId {
                self.selectedTag = allTagsKernel.tags.first {
                    $0.info.tag == tagId &&
                    $0.info.kernel == kernelId &&
                    $0.info.context == state.selectedTagContext
                }
            }
        }

        _selectedKernel.projectedValue
            .sink(receiveValue: { [weak self] in self?.selectedKernelUpdated($0) })
            .store(in: &cancellables)

        self.setUpSearch()
        self.setUpDecoding()

        AppVM.shared.libraryVM = self
    }

    // This is for previews
    convenience init(tagParser: TagParser, selectedTagIdx: Int) {
        self.init(tagParser: tagParser)
        self.selectedTag = self.tagListSections[0].items[selectedTagIdx]
    }

    internal func toggleBit(byteIdx: Int, bitPosition: Int) {
        let bitShift = UInt8.bitWidth - 1 - bitPosition
        var bytes = parseValueBytes(inputString) ?? []
        while bytes.count <= byteIdx {
            bytes.append(0x00)
        }
        bytes[byteIdx] ^= (1 << bitShift)
        inputString = bytes.map { String(format: "%02X", $0) }.joined()
    }

    internal func isDecodable(_ tag: TagDecodingInfo) -> Bool {
        decodableTagIds.contains(tag.info.tag)
    }

    internal func selectNext() { moveSelection(by: 1) }
    internal func selectPrevious() { moveSelection(by: -1) }

    // Sections without applying any search
    private func initialSections(for kernel: KernelInfo) -> [LibraryKernelInfoView.Section] {
        if kernel.needsGeneralKernelTags, let generalKernel {
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

    private func setUpDecoding() {
        $selectedTag
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in onMain { self?.inputString = "" } }
            .store(in: &cancellables)

        Publishers.CombineLatest($selectedTag, $inputString)
            .map { [weak self] (tag, input) -> [TagDetailsVM] in
                guard let self, let tag, !input.isEmpty, isDecodable(tag) else { return [] }
                return decode(tag: tag, input: input)
            }
            .receive(on: RunLoop.main)
            .assign(to: \.tagDetailVMs, on: self)
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
            onMain { self.autoSelectCount += 1 }
        }
    }

    private var flatItems: [TagDecodingInfo] { tagListSections.flatMap(\.items) }

    private func moveSelection(by offset: Int) {
        let items = flatItems
        guard !items.isEmpty else { return }
        let currentIndex = selectedTag.flatMap { tag in items.firstIndex(of: tag) }
        let nextIndex: Int
        if let currentIndex {
            nextIndex = (currentIndex + offset + items.count) % items.count
        } else {
            nextIndex = offset > 0 ? 0 : items.count - 1
        }
        selectedTag = items[nextIndex]
    }

    private func decode(tag: TagDecodingInfo, input: String) -> [TagDetailsVM] {
        guard let valueBytes = parseValueBytes(input), !valueBytes.isEmpty else { return [] }
        let expectedLength = tag.bytes.count
        let paddedBytes: [UInt8]
        if expectedLength > valueBytes.count {
            paddedBytes = valueBytes + Array(repeating: 0x00, count: expectedLength - valueBytes.count)
        } else {
            paddedBytes = valueBytes
        }
        let syntheticHex = tag.info.tag.hexString + berTLVLengthHex(paddedBytes.count) + paddedBytes.hexString
        guard let bertlvs = try? InputParser.parse(input: syntheticHex),
              let bertlv = bertlvs.first else { return [] }

        let enteredCount = valueBytes.count
        let placeholders = tag.placeholderByteVMs

        func makeVM(from decodedTag: EMVTag.DecodedTag) -> TagDetailsVM? {
            guard decodedTag.result.hasBytesOrMapping else { return nil }
            var bytes = decodedTag.result.decodedByteVMs
            if bytes.count > enteredCount {
                bytes = Array(bytes[..<enteredCount]) + Array(placeholders[enteredCount...])
            }
            return .init(
                tag: decodedTag.tagInfo.tag.hexString,
                name: decodedTag.tagInfo.name,
                info: decodedTag.tagInfoVM,
                bytes: bytes,
                kernel: decodedTag.kernel
            )
        }

        switch tagParser.decodeBERTLV(bertlv).decodingResult {
        case .unknown:
            return []
        case .singleKernel(let decodedTag):
            return makeVM(from: decodedTag).map { [$0] } ?? []
        case .multipleKernels(let decodedTags):
            return decodedTags.compactMap(makeVM)
        }
    }

    private func parseValueBytes(_ input: String) -> [UInt8]? {
        let cleaned = input
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
        let hexInput = cleaned.count % 2 != 0 ? String(cleaned.dropLast()) : cleaned
        let hexBytes = hexInput.split(by: 2).map { UInt8($0, radix: 16) }
        let compacted = hexBytes.compactMap { $0 }
        if hexBytes.count == compacted.count, !compacted.isEmpty {
            return compacted
        }
        if let data = Data(base64Encoded: input, options: .ignoreUnknownCharacters), !data.isEmpty {
            return [UInt8](data)
        }
        return nil
    }

    private func berTLVLengthHex(_ count: Int) -> String {
        if count <= 0x7F {
            return String(format: "%02X", count)
        } else if count <= 0xFF {
            return String(format: "81%02X", count)
        } else {
            return String(format: "82%04X", count)
        }
    }

}

fileprivate let allTags = "All Tags"
fileprivate let allTagsKernelId = "All tags"
fileprivate let generalKernelId = "general"

extension KernelInfo: @retroactive Hashable {

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

    var placeholderByteVMs: [DecodedByteVM] {
        bytes
            .map { try? EMVTag.DecodedByte(byte: 0x00, info: $0) }
            .enumerated()
            .compactMap(t2FlatMap(_:))
            .map { $0.1.decodedByteVM(idx: $0.0, isPlaceholder: true) }
    }

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
