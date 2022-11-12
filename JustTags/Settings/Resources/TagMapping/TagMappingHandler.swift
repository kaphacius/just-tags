//
//  TagMappingHandler.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 09/11/2022.
//

import SwiftyEMVTags
import SwiftUI

typealias TagMappingRepo = CustomResourceRepo<TagMapper>

extension TagMapping: CustomResource {
    
    static let folderName = "TagMapping"
    static let iconName = "books.vertical.fill"
    static let settingsPage = "Kernels"
    static let displayName = "Tag Mapping"
    public var id: String { tag.hexString }
    
}

extension TagMapper: CustomResourceHandler {
    
    typealias Resource = TagMapping
    
    func addCustomResource(_ resource: TagMapping) throws {
        try addTagMapping(newMapping: resource)
    }
    
    func removeCustomResource(with identifier: String) throws {
        guard let tag = UInt64(identifier, radix: 16) else {
            // TODO: handle error
            return
        }
        try removeTagMapping(tag: tag)
    }
    
    var identifiers: [String] {
        mappedTags
    }
    
    var resources: [SwiftyEMVTags.TagMapping] {
        Array(mappings.values)
    }
    
}
