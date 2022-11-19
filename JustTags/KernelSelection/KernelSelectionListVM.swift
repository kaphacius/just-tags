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
    
    @Published internal var rowVMs: [KernelSelectionRowVM]
    @Published internal var tagParser: TagParser
    
    init(tagParser: TagParser) {
        self.rowVMs = tagParser.initialKernels.map {
            .init(
                id: $0.id,
                name: $0.name
            )
        }
        self.tagParser = tagParser
    }
    
    internal func isOnBinding(for id: String) -> Binding<Bool> {
        .init(
            get: { self.tagParser.selectedKernelIds.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    self.tagParser.selectedKernelIds.insert(id)
                } else {
                    self.tagParser.selectedKernelIds.remove(id)
                }
                self.objectWillChange.send()
            }
        )
    }
    
}
