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
    internal var activeKernels: [KernelInfo] {
        initialKernels.filter { selectedKernelIds.contains($0.id) }
    }
    internal var initialKernels: [KernelInfo] {
        tagDecoder.activeKernels
    }
    
    private var initialKernelIds: [String]
    private var cancellables: Set<AnyCancellable> = []
    
    init(tagDecoder: TagDecoder) {
        self.initialKernelIds = tagDecoder.kernelIds
        self.selectedKernelIds = Set(tagDecoder.kernelIds)
        self.tagDecoder = tagDecoder
        
        tagDecoder.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateKernels() }
            .store(in: &cancellables)
    }
    
    internal func selectKernels(from tags: [EMVTag]) {
        let detected = Set(detectedKernelNumbers(in: tags).map { "kernel\($0)" })
        let builtInIds = Set(initialKernelIds)
        let applicable = detected.intersection(builtInIds)
        let customSelected = selectedKernelIds.subtracting(builtInIds)
        selectedKernelIds = (applicable.isEmpty ? builtInIds : applicable
            .union(builtInIds.filter { $0 == "general" }))
            .union(customSelected)
    }

    private func detectedKernelNumbers(in tags: [EMVTag]) -> Set<Int> {
        tags.reduce(into: Set<Int>()) { result, tag in
            kernelNumber(from: tag).map { result.insert($0) }
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
