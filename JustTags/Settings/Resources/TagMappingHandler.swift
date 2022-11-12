//
//  TagMappingHandler.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 09/11/2022.
//

import SwiftyEMVTags
import SwiftUI

extension TagMapping: CustomResource {
    
    static let folderName = "TagMapping"
    static let iconName = "books.vertical.fill"
    static let settingsPage = "Kernels"
    var identifier: String { tag.hexString }
    
}

struct TagMappingHandler: CustomResourceHandler {
    
    typealias P = TagMapping
    
    var identifiers: [String] {
        tagDecoder.kernels
    }
    
    private let tagDecoder: TagDecoder
    
    init(tagDecoder: TagDecoder) {
        self.tagDecoder = tagDecoder
    }
    
    func addCustomResource(_ resource: TagMapping) throws {
        try tagDecoder.tagMapper.addTagMapping(newMapping: resource)
        Task { @MainActor in
            withAnimation {
                tagDecoder.objectWillChange.send()
            }
        }
    }
    
    func removeCustomResource(with identifier: String) throws {
        guard let tag = UInt64(identifier, radix: 16) else {
            // TODO: handle error
            return
        }
        try tagDecoder.tagMapper.removeTagMapping(tag: tag)
        Task { @MainActor in
            withAnimation {
                tagDecoder.objectWillChange.send()
            }
        }
    }
    
}
