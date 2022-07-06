//
//  TagsDataSource.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 30/03/2022.
//

import SwiftUI
import Foundation
import SwiftyEMVTags

internal final class TagsDataSource: ObservableObject, Identifiable {
    
    internal let id = UUID()
    
    @Published internal var tags: [EMVTag]
    @Published internal var disclosureGroups: [UUID: Bool] = [:]
    
    internal init(tags: [EMVTag]) {
        self.tags = tags
    }
}
