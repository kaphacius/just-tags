//
//  KernelSelectionListVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 18/11/2022.
//

import Foundation
import SwiftyEMVTags
import SwiftUI

final class KernelSelectionListVM: ObservableObject {
    
    @Published internal var rowVMs: [KernelSelectionRowVM] = []
    @Published internal var selectedKernels: Set<String>
    
    init(tagDecoder: TagDecoder) {
        self.selectedKernels = Set(tagDecoder.identifiers)
        self.rowVMs = tagDecoder.kernelsInfo.values.map {
            .init(
                kernelName: $0.description,
                kernelId: $0.name
            )
        }
    }
    
    internal func isOnBinding(for id: String) -> Binding<Bool> {
        .init(
            get: { self.selectedKernels.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    self.selectedKernels.insert(id)
                } else {
                    self.selectedKernels.remove(id)
                }
            }
        )
    }
    
}
