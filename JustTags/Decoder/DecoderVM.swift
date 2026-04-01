//
//  DecoderVM.swift
//  JustTags
//

import SwiftyEMVTags
import SwiftUI
import Combine

internal final class DecoderVM: ObservableObject {

    internal struct Section: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let items: [TagDecodingInfo]
    }

    @Published internal var searchText = ""
    @Published internal var selectedTag: TagDecodingInfo?
    @Published internal var inputString = ""
    @Published internal var tagDetailVMs: [TagDetailsVM] = []
    @Published internal var sections: [Section] = []
    @Published internal var autoSelectCount: Int = 0

    internal let allDecodableTags: [TagDecodingInfo]
    private let tagParser: TagParser
    private var cancellables: Set<AnyCancellable> = []
    private let tagSearchComponents: [Int: PrioritySearchComponents]
    private var initialSections: [Section]

    init(tagParser: TagParser) {
        self.tagParser = tagParser

        // Filter to decodable tags first, then deduplicate by tag ID.
        // Filtering before deduplication ensures that if a tag appears in multiple
        // kernels, a decodable variant is preferred over a non-decodable one.
        var seenTagIds = Set<UInt64>()
        self.allDecodableTags = tagParser.initialKernels
            .flatMap(\.tags)
            .filter { tagInfo in
                tagInfo.bytes.count > 0 ||
                tagParser.tagMapper.mappings[tagInfo.info.tag] != nil
            }
            .filter { seenTagIds.insert($0.info.tag).inserted }
            .sorted()

        let initialSection = Section(title: "", items: self.allDecodableTags)
        self.initialSections = [initialSection]
        self.sections = [initialSection]

        self.tagSearchComponents = .init(
            uniqueKeysWithValues: self.allDecodableTags.map(\.searchPair)
        )

        setUpSearch()
        setUpDecoding()
    }

    private func setUpSearch() {
        _searchText.projectedValue
            .debounce(for: 0.10, scheduler: RunLoop.main)
            .removeDuplicates()
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
                guard let self, let tag else { return [] }
                if input.isEmpty {
                    return self.infoOnlyVMs(for: tag)
                }
                let decoded = self.decode(tag: tag, input: input)
                return decoded.isEmpty ? self.infoOnlyVMs(for: tag) : decoded
            }
            .receive(on: RunLoop.main)
            .assign(to: \.tagDetailVMs, on: self)
            .store(in: &cancellables)
    }

    private func infoOnlyVMs(for tag: TagDecodingInfo) -> [TagDetailsVM] {
        tagParser.initialKernels
            .compactMap { $0.tags.first(where: { $0.info.tag == tag.info.tag }) }
            .filter { $0.bytes.count > 0 || tagParser.tagMapper.mappings[$0.info.tag] != nil }
            .map { TagDetailsVM(tag: $0.info.tag.hexString, name: $0.info.name, info: $0.info.tagInfoVM, bytes: [], kernel: $0.info.kernel) }
    }

    private func decode(tag: TagDecodingInfo, input: String) -> [TagDetailsVM] {
        guard let valueBytes = parseValueBytes(input), !valueBytes.isEmpty else { return [] }
        let syntheticHex = tag.info.tag.hexString + berTLVLengthHex(valueBytes.count) + valueBytes.hexString
        guard let bertlvs = try? InputParser.parse(input: syntheticHex),
              let bertlv = bertlvs.first else { return [] }
        switch tagParser.decodeBERTLV(bertlv).decodingResult {
        case .unknown:
            return []
        case .singleKernel(let decodedTag):
            return decodedTag.result.hasBytesOrMapping ? [decodedTag.tagDetailsVM] : []
        case .multipleKernels(let decodedTags):
            return decodedTags.filter(\.result.hasBytesOrMapping).map(\.tagDetailsVM)
        }
    }

    private func parseValueBytes(_ input: String) -> [UInt8]? {
        let cleaned = input
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
        let hexBytes = cleaned.split(by: 2).map { UInt8($0, radix: 16) }
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

    private func searchTags(_ text: String) {
        if shouldSearch(with: text) {
            performSearch(text)
        } else if initialSections != sections {
            sections = initialSections
        }
    }

    private func shouldSearch(with text: String) -> Bool {
        if text.count > 2 { return true }
        if text.count == 2, UInt64(text, radix: 16) != nil { return true }
        return false
    }

    private func performSearch(_ searchText: String) {
        let words = Set(
            searchText
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .whitespaces)
        ).filter { $0.count > 1 }

        let filtered = filterPrioritySearchable(
            initial: allDecodableTags,
            allSearchComponents: tagSearchComponents,
            words: words
        )
        sections = [
            .init(title: "Best matches", items: filtered.bestMatches),
            .init(title: "More...", items: filtered.more)
        ]

        let allResults = filtered.bestMatches + filtered.more
        if allResults.count == 1 {
            selectedTag = allResults[0]
            onMain { self.autoSelectCount += 1 }
        }
    }

    internal func selectNext() { moveSelection(by: 1) }
    internal func selectPrevious() { moveSelection(by: -1) }

    private var flatItems: [TagDecodingInfo] { sections.flatMap(\.items) }

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

}
