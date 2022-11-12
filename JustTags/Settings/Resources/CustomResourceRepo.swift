//
//  CustomResourceRepo.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 05/11/2022.
//

import Foundation
import SwiftUI
import SwiftyEMVTags

internal class CustomResourceRepo<H: CustomResourceHandler>: ObservableObject {
    
    @Published var names: [String]
    
    private let resourcesDir: URL
    private let handler: H
    private var filenames: Dictionary<String, String> = [:]
    internal var customIdentifiers: [String] { Array(filenames.keys) }
    
    init?(handler: H) {
        self.handler = handler
        
        guard let resourcesDir = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory, .userDomainMask, true
        )
            .first
            .map(URL.init(fileURLWithPath:))
            .map({ $0.appendingPathComponent(H.Resource.folderName, isDirectory: true) }) else {
            return nil
        }
        
        self.resourcesDir = resourcesDir
        self.names = handler.identifiers
    }
    
    internal func loadSavedResources() throws {
        guard FileManager.default.fileExists(atPath: resourcesDir.path) else {
            // Nothing to load
            return
        }
        
        try FileManager.default.contentsOfDirectory(atPath: resourcesDir.path)
            .map(resourcesDir.appendingPathComponent)
            .map { (try Data(contentsOf: $0), $0.lastPathComponent) }
            .map { (try JSONDecoder().decode(H.Resource.self, from: $0.0), $0.1) }
            .map { (resource, filename) in
                self.filenames[resource.identifier] = filename
                self.names.append(resource.identifier)
                return resource
            }.forEach {
                try handler.addCustomResource($0)
            }
        
        self.names = names.sorted()
    }
    
    internal func addNewResource(at url: URL) throws {
        let data = try Data(contentsOf: url)
        let newResource = try JSONDecoder().decode(H.Resource.self, from: data)
        try handler.addCustomResource(newResource)
        // TODO: check if resource already exists
        try saveResource(at: url, identifier: newResource.identifier)
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
        names.append(identifier)
        names = names.sorted()
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
        _ = names.firstIndex(of: identifier).map { names.remove(at: $0) }
    }
    
    private func pathForResource(with identifier: String) -> URL? {
        filenames[identifier]
            .map { resourcesDir
                .appendingPathComponent($0)
                .appendingPathExtension(for: .json)
            }
    }
    
}
