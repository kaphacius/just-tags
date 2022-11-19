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

extension TagDecoder: ObservableObject { }

internal final class TagParser: ObservableObject, AnyTagDecoder {
    
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
