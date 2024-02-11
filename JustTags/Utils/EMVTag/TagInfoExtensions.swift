//
//  TagInfoExtensions.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 13/01/2023.
//

import Foundation
import SwiftyEMVTags

extension TagInfo: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(tag)
        hasher.combine(context)
        hasher.combine(kernel)
    }
    
}

extension TagDecodingInfo: Hashable {
    
    public static func == (lhs: TagDecodingInfo, rhs: TagDecodingInfo) -> Bool {
        lhs.info.tag == rhs.info.tag &&
        lhs.info.kernel == rhs.info.kernel &&
        lhs.info.context == rhs.info.context
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.info.tag)
        hasher.combine(self.info.context)
        hasher.combine(self.info.kernel)
    }
    
}

extension TagDecodingInfo: Comparable {
    
    public static func < (lhs: TagDecodingInfo, rhs: TagDecodingInfo) -> Bool {
        lhs.info.tag < rhs.info.tag
    }
    
}
