//
//  CustomResourceRepo.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 05/11/2022.
//

import Foundation
import SwiftUI
import SwiftyEMVTags

internal struct JustTagsError: Error {
    
    internal let message: String
    
}

protocol CustomResource: Decodable {
    
    static var folderName: String { get }
    var identifier: String { get }
    
}

protocol CustomResourceHandler {
    
    associatedtype P: CustomResource
    
    func addCustomResource(_ resource: P) throws
    func removeCustomResource(with identifier: String) throws
    var identifiers: [String] { get }
    
}

struct KernelInfoHandler: CustomResourceHandler {
    
    typealias P = KernelInfo
    
    var identifiers: [String] {
        tagDecoder.kernels
    }
    
    private let tagDecoder: TagDecoder
    
    init(tagDecoder: TagDecoder) {
        self.tagDecoder = tagDecoder
    }
    
    func addCustomResource(_ resource: KernelInfo) throws {
        try tagDecoder.addKernelInfo(newInfo: resource)
        Task { @MainActor in
            withAnimation {
                tagDecoder.objectWillChange.send()
            }
        }
    }
    
    func removeCustomResource(with identifier: String) throws {
        tagDecoder.removeKernelInfo(with: identifier)
        Task { @MainActor in
            withAnimation {
                tagDecoder.objectWillChange.send()
            }
        }
    }
    
}

extension KernelInfo: CustomResource {
    
    
    var identifier: String { name }
    static let folderName = "KernelInfo"
    
}

extension TagMapping: CustomResource {
    
    static let folderName = "TagMapping"
    var identifier: String { tag.hexString }
    
}

internal class CustomResourceRepo<T: CustomResourceHandler>: ObservableObject {
    
    private let resourcesDir: URL
    private let handler: T
    private var filenames: Dictionary<String, String> = [:]
    internal var resources: [String] { Array(filenames.keys) }
    
    init?(handler: T) {
        self.handler = handler
        
        guard let resourcesDir = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory, .userDomainMask, true
        )
            .first
            .map(URL.init(fileURLWithPath:))
            .map({ $0.appendingPathComponent(T.P.folderName, isDirectory: true) }) else {
            return nil
        }
        
        self.resourcesDir = resourcesDir
    }
    
    internal func loadSavedResources() throws {
        guard FileManager.default.fileExists(atPath: resourcesDir.path) else {
            // Nothing to load
            return
        }
        
        try FileManager.default.contentsOfDirectory(atPath: resourcesDir.path)
            .map(resourcesDir.appendingPathComponent)
            .map { (try Data(contentsOf: $0), $0.lastPathComponent) }
            .map { (try JSONDecoder().decode(T.P.self, from: $0.0), $0.1) }
            .map { (resource, filename) in
                self.filenames[resource.identifier] = filename
                return resource
            }.forEach {
                try handler.addCustomResource($0)
            }
    }
    
    internal func addNewResource(at url: URL) throws {
        let data = try Data(contentsOf: url)
        let newResource = try JSONDecoder().decode(T.P.self, from: data)
        try handler.addCustomResource(newResource)
        // TODO: check if resource already exists
        try saveResource(at: url, identifier: newResource.identifier)
        Task { @MainActor in
            withAnimation {
//                tagDecoder.objectWillChange.send()
            }
        }
    }
    
    private func saveResource(at url: URL, identifier: String) throws {
        if FileManager.default.fileExists(atPath: resourcesDir.path) == false {
            try FileManager.default.createDirectory(
                at: resourcesDir,
                withIntermediateDirectories: false
            )
        }
        
        let newPath = resourcesDir
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(for: .json)
        
        try FileManager.default.copyItem(at: url, to: newPath)
        
        filenames[identifier] = newPath.lastPathComponent
    }
    
    internal func removeResource(with identifier: String) throws {
        guard handler.identifiers.contains(identifier),
              let resourcePath = pathForResource(with: identifier),
              FileManager.default.fileExists(atPath: resourcePath.path)
        else {
            // Nothing to delete
            return
        }
        
        try FileManager.default.removeItem(at: resourcePath)
        try handler.removeCustomResource(with: identifier)
    }
    
    private func pathForResource(with identifier: String) -> URL? {
        filenames[identifier]
            .map { resourcesDir
                .appendingPathComponent($0)
                .appendingPathExtension(for: .json)
            }
    }
    
}
