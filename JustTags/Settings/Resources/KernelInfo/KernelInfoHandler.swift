//
//  KernelInfoHandler.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 09/11/2022.
//

import SwiftyEMVTags
import SwiftUI

extension KernelInfo: CustomResource {
    
    static let folderName = "KernelInfo"
    static let iconName = "text.book.closed.fill"
    static let settingsPage = "Kernels"
    static let displayName = "Kernel info"
    var identifier: String { name }
    
}

typealias KernelInfoRepo = CustomResourceRepo<KernelInfoHandler>

struct KernelInfoHandler: CustomResourceHandler {
    
    typealias Resource = KernelInfo
    
    var identifiers: [String] {
        tagDecoder.kernels
    }
    
    var resources: [KernelInfo] {
        Array(tagDecoder.kernelsInfo.values)
    }
    
    private let tagDecoder: TagDecoder
    
    init(tagDecoder: TagDecoder) {
        self.tagDecoder = tagDecoder
    }
    
    func addCustomResource(_ resource: KernelInfo) throws {
        try tagDecoder.addKernelInfo(newInfo: resource)
    }
    
    func removeCustomResource(with identifier: String) throws {
        tagDecoder.removeKernelInfo(with: identifier)
    }
    
}
