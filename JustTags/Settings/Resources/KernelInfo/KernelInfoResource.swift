//
//  KernelInfoHandler.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 09/11/2022.
//

import SwiftyEMVTags
import SwiftUI

typealias KernelInfoRepo = CustomResourceRepo<KernelInfo>

extension KernelInfo: CustomResource {
    
    typealias View = KernelInfoView
    
    static let folderName = "KernelInfo"
    static let iconName = "text.book.closed.fill"
    static let settingsPage = "Kernels"
    static let displayName = "Kernel info"
    
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
        kernelIds
    }
    
    var resources: [SwiftyEMVTags.KernelInfo] {
        Array(kernelsInfo.values)
    }
    
    func publishChanges() {
        self.objectWillChange.send()
    }
    
}
