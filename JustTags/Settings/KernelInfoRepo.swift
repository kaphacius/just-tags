//
//  KernelInfoRepo.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 05/11/2022.
//

import Foundation
import SwiftUI
import SwiftyEMVTags

private let kernelsDirPath = NSSearchPathForDirectoriesInDomains(
    .applicationSupportDirectory, .userDomainMask, true)
    .first
    .map(URL.init(fileURLWithPath:))
    .map { $0.appendingPathComponent("KernelInfo", isDirectory: true) }

internal func loadSavedKernelInfo(for tagDecoder: TagDecoder) throws {
    guard let dirPath = kernelsDirPath else {
        // TODO: Handle this?
        return
    }
    
    guard FileManager.default.fileExists(atPath: dirPath.path) else {
        // Nothing to load
        return
    }
    
    try FileManager.default.contentsOfDirectory(atPath: dirPath.path)
        .map(dirPath.appendingPathComponent)
        .map { try Data(contentsOf: $0) }
        .forEach(tagDecoder.addKernelInfo(data:))
}
    
internal func addNewKernelInfo(at url: URL, tagDecoder: TagDecoder) throws {
    let data = try Data(contentsOf: url)
    try tagDecoder.addKernelInfo(data: data)
    // TODO: check if kernel already exists
    saveNewKernelInfo(url: url, tagDecoder: tagDecoder)
    Task { @MainActor in
        tagDecoder.objectWillChange.send()
    }
}

internal func saveNewKernelInfo(url: URL, tagDecoder: TagDecoder) {
    guard let dirPath = kernelsDirPath else {
        // TODO: Handle this?
        return
    }
    
    do {
        if FileManager.default.fileExists(atPath: dirPath.path) == false {
            try FileManager.default.createDirectory(
                at: dirPath,
                withIntermediateDirectories: false
            )
        }
        
        try FileManager.default.copyItem(
            at: url,
            to: dirPath.appendingPathComponent(url.lastPathComponent)
        )
    } catch {
        // TODO: handle errors
        print(error)
    }
}
