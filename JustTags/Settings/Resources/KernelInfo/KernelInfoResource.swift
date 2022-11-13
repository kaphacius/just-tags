//
//  KernelInfoHandler.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 09/11/2022.
//

import SwiftyEMVTags
import SwiftUI

typealias KernelInfoRepo = CustomResourceRepo<TagDecoder>

extension KernelInfo: CustomResource {
    
    static let folderName = "KernelInfo"
    static let iconName = "text.book.closed.fill"
    static let settingsPage = "Kernels"
    static let displayName = "Kernel info"
    public var id: String { name }
    
    public static func == (lhs: KernelInfo, rhs: KernelInfo) -> Bool {
        lhs.name == rhs.name
    }
    
    public static func < (lhs: KernelInfo, rhs: KernelInfo) -> Bool {
        lhs.name < rhs.name
    }
    
}

extension TagDecoder: CustomResourceHandler {
    
    typealias Resource = KernelInfo
    
    func addCustomResource(_ resource: KernelInfo) throws {
        try addKernelInfo(newInfo: resource)
    }
    
    func removeCustomResource(with identifier: String) throws {
        removeKernelInfo(with: identifier)
    }
    
    var identifiers: [String] {
        kernels
    }
    
    var resources: [SwiftyEMVTags.KernelInfo] {
        Array(kernelsInfo.values)
    }
    
}
