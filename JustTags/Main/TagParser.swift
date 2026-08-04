//
//  TagParser.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 19/11/2022.
//

import SwiftyEMVTags
import SwiftyBERTLV
import Combine
import SwiftUI

extension TagDecoder: @retroactive ObservableObject { }

internal final class TagParser: ObservableObject, AnyTagDecoder {

    private static let ridToKernelNumber: [String: Int] = [
        "A000000003": 3,  // Visa
        "A000000004": 2,  // MasterCard
        "A000000025": 4,  // American Express
        "A000000065": 5,  // JCB
    ]

    private static let aidTagCodes: Set<UInt64> = [0x9F06, 0x4F, 0x84]
    private static let kernelIdTagCodes: Set<UInt64> = [0x9F2A, 0xDF810C]

    internal var tagMapper: TagMapper { tagDecoder.tagMapper }
    internal var selectedKernelIds: Set<String> {
        didSet { self.objectWillChange.send() }
    }

    private var tagDecoder: TagDecoder
    private let kernelInfoRepo: KernelInfoRepo
    internal var activeKernels: [KernelInfo] {
        initialKernels.filter { selectedKernelIds.contains($0.id) }
    }
    internal var initialKernels: [KernelInfo] {
        tagDecoder.activeKernels
    }

    /// Ids of kernels that were imported/persisted as custom resources, sourced from
    /// `KernelInfoRepo` directly rather than inferred from load order - this stays
    /// correct regardless of whether custom kernels were restored before or after this
    /// `TagParser` was created.
    internal var customKernelIds: Set<String> {
        Set(kernelInfoRepo.customIdentifiers)
    }

    private var builtInKernelIds: Set<String> {
        Set(tagDecoder.kernelIds).subtracting(customKernelIds)
    }

    private var initialKernelIds: [String]
    private var cancellables: Set<AnyCancellable> = []

    init(tagDecoder: TagDecoder, kernelInfoRepo: KernelInfoRepo) {
        self.kernelInfoRepo = kernelInfoRepo
        self.initialKernelIds = tagDecoder.kernelIds
        self.selectedKernelIds = Set(tagDecoder.kernelIds)
        self.tagDecoder = tagDecoder

        tagDecoder.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateKernels() }
            .store(in: &cancellables)
    }

    internal func selectKernels(from tags: [EMVTag]) {
        let builtInKernelIds = self.builtInKernelIds
        let detected = Set(detectedKernelNumbers(in: tags).map { "kernel\($0)" })
        let applicable = detected.intersection(builtInKernelIds)
        let selectedBuiltIns = (applicable.isEmpty ? builtInKernelIds : applicable
            .union(builtInKernelIds.filter { $0 == "general" }))
        selectedKernelIds = selectedBuiltIns
            .union(selectedCustomKernelIds(from: tags))
    }

    private func detectedKernelNumbers(in tags: [EMVTag]) -> Set<Int> {
        tags.reduce(into: Set<Int>()) { result, tag in
            _ = kernelNumber(from: tag).map { result.insert($0) }
            if case .constructed(let subtags) = tag.category {
                result.formUnion(detectedKernelNumbers(in: subtags))
            }
        }
    }

    private func kernelNumber(from tag: EMVTag) -> Int? {
        let code = tag.tag.tag
        if Self.aidTagCodes.contains(code), tag.tag.value.count >= 5 {
            let rid = tag.tag.value.prefix(5).map { String(format: "%02X", $0) }.joined()
            return Self.ridToKernelNumber[rid]
        } else if Self.kernelIdTagCodes.contains(code), let byte = tag.tag.value.first {
            return Int(byte)
        }
        return nil
    }

    private func selectedCustomKernelIds(from tags: [EMVTag]) -> Set<String> {
        let customKernels = customKernelIds.compactMap { tagDecoder.kernelsInfo[$0] }
        return Self.selectedCustomKernelIds(from: tags, among: customKernels)
    }

    /// Determines which custom kernels should auto-activate for the given tag set.
    ///
    /// Each custom kernel scores its declared `triggerTags` against the tag codes
    /// present anywhere in `tags`. A kernel with no declared trigger tags never
    /// auto-activates. Kernels connected via (symmetric) `exclusiveWith` are grouped:
    /// only the highest scorer in a group activates, and any tie (including a 0-0 tie)
    /// activates none of them.
    internal static func selectedCustomKernelIds(
        from tags: [EMVTag],
        among customKernels: [KernelInfo]
    ) -> Set<String> {
        guard customKernels.isEmpty == false else { return [] }

        let presentTagCodes = flatTagCodes(in: tags)
        let scores = Dictionary(uniqueKeysWithValues: customKernels.map { kernel in
            (kernel.id, Set(kernel.triggerTags).intersection(presentTagCodes).count)
        })

        return exclusionGroups(of: customKernels).reduce(into: Set<String>()) { result, group in
            let maxScore = group.compactMap { scores[$0] }.max() ?? 0
            guard maxScore >= 1 else { return }

            let winners = group.filter { (scores[$0] ?? 0) == maxScore }
            if winners.count == 1 {
                result.insert(winners[0])
            }
        }
    }

    /// Groups kernel ids into connected components via the symmetric closure of
    /// `exclusiveWith` - a kernel with no exclusions of its own forms a group of one.
    internal static func exclusionGroups(of kernels: [KernelInfo]) -> [[String]] {
        let idsInScope = Set(kernels.map(\.id))
        var adjacency: [String: Set<String>] = [:]
        for kernel in kernels {
            for otherId in kernel.exclusiveWith where idsInScope.contains(otherId) {
                adjacency[kernel.id, default: []].insert(otherId)
                adjacency[otherId, default: []].insert(kernel.id)
            }
        }

        var visited: Set<String> = []
        var groups: [[String]] = []
        for kernel in kernels {
            guard visited.contains(kernel.id) == false else { continue }

            var group: [String] = []
            var stack = [kernel.id]
            while let id = stack.popLast() {
                guard visited.insert(id).inserted else { continue }
                group.append(id)
                stack.append(contentsOf: adjacency[id, default: []])
            }
            groups.append(group)
        }

        return groups
    }

    internal static func flatTagCodes(in tags: [EMVTag]) -> Set<UInt64> {
        tags.reduce(into: Set<UInt64>()) { result, tag in
            result.insert(tag.tag.tag)
            if case .constructed(let subtags) = tag.category {
                result.formUnion(flatTagCodes(in: subtags))
            }
        }
    }

    private func updateKernels() {
        if self.initialKernelIds.count < tagDecoder.kernelIds.count {
            // If a new kernel is added - select it by default
            let newKernels = Set(tagDecoder.kernelIds).subtracting(self.initialKernelIds)
            newKernels.forEach { self.selectedKernelIds.insert($0) }
        } else {
            // If a kernel is deleted - make sure it is deselected
            self.selectedKernelIds = selectedKernelIds.intersection(tagDecoder.kernelIds)
        }
        
        self.initialKernelIds = tagDecoder.kernelIds.sorted()
    }
    
}
