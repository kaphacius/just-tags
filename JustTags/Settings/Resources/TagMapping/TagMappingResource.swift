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
    
    public typealias ID = UInt64
    
    static let folderName = "TagMapping"
    static let iconName = "books.vertical.fill"
    static let settingsPage = "Mappings"
    static let displayName = "Tag Mapping"
    public var id: UInt64 { tag }
    
    public static func == (lhs: TagMapping, rhs: TagMapping) -> Bool {
        lhs.id == rhs.id
    }
    
    public static func < (lhs: TagMapping, rhs: TagMapping) -> Bool {
        lhs.id < rhs.id
    }
    
}

extension TagMapper: CustomResourceHandler {
    
    typealias Resource = TagMapping
    
    func addCustomResource(_ resource: TagMapping) throws {
        try addTagMapping(newMapping: resource)
    }
    
    func removeCustomResource(with id: Resource.ID) throws {
        try removeTagMapping(tag: id)
    }
    
    var identifiers: [Resource.ID] {
        Array(mappings.keys).sorted()
    }
    
    var resources: [SwiftyEMVTags.TagMapping] {
        Array(mappings.values)
    }
    
}
