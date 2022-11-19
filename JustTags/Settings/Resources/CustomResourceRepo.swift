//
//  CustomResourceRepo.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 05/11/2022.
//

import Foundation
import SwiftUI
import SwiftyEMVTags

internal class CustomResourceRepo<Resource: CustomResource>: ObservableObject {
    
    @Published var resources: [Resource]
    
    private let resourcesDir: URL
    private let handler: any CustomResourceHandler<Resource, Resource.ID>
    private var filenames: Dictionary<Resource.ID, String> = [:]
    internal var customIdentifiers: [Resource.ID] { Array(filenames.keys) }
    
    init?(handler: any CustomResourceHandler<Resource, Resource.ID>) {
        self.handler = handler
        
        guard let resourcesDir = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory, .userDomainMask, true
        )
            .first
            .map(URL.init(fileURLWithPath:))
            .map({ $0.appendingPathComponent(Resource.folderName, isDirectory: true) }) else {
            return nil
        }

        self.resourcesDir = resourcesDir
        self.resources = handler.resources
    }
    
    internal func loadSavedResources() throws {
        guard FileManager.default.fileExists(atPath: resourcesDir.path) else {
            // Nothing to load
            return
        }

        try FileManager.default.contentsOfDirectory(atPath: resourcesDir.path)
            .map(resourcesDir.appendingPathComponent)
            .map { (try Data(contentsOf: $0), $0.lastPathComponent) }
            .map { (try JSONDecoder().decode(Resource.self, from: $0.0), $0.1) }
            .map { (resource, filename) in
                self.filenames[resource.id] = filename
                return resource
            }.forEach {
                try handler.addCustomResource($0)
            }

        updateResources()
    }

    internal func addNewResource(at url: URL) throws {
        let data = try Data(contentsOf: url)
        let newResource = try JSONDecoder().decode(Resource.self, from: data)
        try handler.addCustomResource(newResource)
        try saveResource(at: url, identifier: newResource.id)
        updateResources()
    }

    private func saveResource(at url: URL, identifier: Resource.ID) throws {
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

    internal func removeResource(with identifier: Resource.ID) throws {
        guard handler.identifiers.contains(identifier),
              let resourcePath = pathForResource(with: identifier),
              FileManager.default.fileExists(atPath: resourcePath.path)
        else {
            // Nothing to delete
            return
        }

        try FileManager.default.removeItem(at: resourcePath)
        try handler.removeCustomResource(with: identifier)
        updateResources()
    }

    private func updateResources() {
        Task { @MainActor in
            self.resources = handler.resources.sorted()
            handler.publishChanges()
        }
    }

    private func pathForResource(with identifier: Resource.ID) -> URL? {
        filenames[identifier]
            .map { resourcesDir
                .appendingPathComponent($0)
                .appendingPathExtension(for: .json)
            }
    }
    
}
