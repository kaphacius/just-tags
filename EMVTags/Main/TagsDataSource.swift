//
//  TagsDataSource.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 30/03/2022.
//

import Foundation
import SwiftyEMVTags

internal final class TagsDataSource: ObservableObject {
    @Published internal var tags: [EMVTag]
    
    internal init(tags: [EMVTag]) {
        self.tags = tags
    }
}
