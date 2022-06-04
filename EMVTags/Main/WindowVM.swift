//
//  WindowVM.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 18/05/2022.
//

import Foundation
import SwiftyEMVTags
import SwiftUI

internal final class WindowVW: ObservableObject {
    
    @Published internal var dataSource = TagsDataSource(tags: [])
    @Published internal var selectedTag: EMVTag? = nil
    @Published private(set) var selectedIds = Set<UUID>()
    @Published private(set) var selectedTags = [EMVTag]()
    
    internal func onTagSelected(tag: EMVTag) {
        if selectedIds.contains(tag.id) {
            selectedIds.remove(tag.id)
            _ = selectedTags
                .firstIndex(of: tag)
                .map{ selectedTags.remove(at: $0) }
        } else {
            selectedIds.insert(tag.id)
            selectedTags.append(tag)
        }
    }
    
    internal func contains(id: UUID) -> Bool {
        selectedIds.contains(id)
    }
    
    internal var hexString: String {
        selectedTags.map(\.hexString).joined()
    }
    
}
