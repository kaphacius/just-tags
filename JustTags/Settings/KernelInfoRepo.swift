//
//  KernelInfoRepo.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 05/11/2022.
//

import Foundation
import SwiftUI
import SwiftyEMVTags

internal class KernelInfoRepo: ObservableObject {
    
    private let kernelsDirPath: URL
    private let tagDecoder: TagDecoder
    
    private var kernelFilenames: Dictionary<String, String> = [:]
    
    internal init?(tagDecoder: TagDecoder) {
        guard let kernelsDirPath = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory, .userDomainMask, true
        )
            .first
            .map(URL.init(fileURLWithPath:))
            .map({ $0.appendingPathComponent("KernelInfo", isDirectory: true) }) else {
            return nil
        }
        
        self.kernelsDirPath = kernelsDirPath
        self.tagDecoder = tagDecoder
    }
    
    internal func isKernelInfoSaved(with name: String) -> Bool {
        kernelFilenames.keys.contains(name)
    }
    
    internal func loadSavedKernelInfo() throws {
        guard FileManager.default.fileExists(atPath: kernelsDirPath.path) else {
            // Nothing to load
            return
        }
        
        try FileManager.default.contentsOfDirectory(atPath: kernelsDirPath.path)
            .map(kernelsDirPath.appendingPathComponent)
            .map { (try Data(contentsOf: $0), $0.lastPathComponent) }
            .map { (try JSONDecoder().decode(KernelInfo.self, from: $0.0), $0.1) }
            .map { (kernelInfo, kernelFilename) in
                self.kernelFilenames[kernelInfo.name] = kernelFilename
                return kernelInfo
            }
            .forEach(tagDecoder.addKernelInfo(newInfo:))
    }
    
    internal func addNewKernelInfo(at url: URL) throws {
        let data = try Data(contentsOf: url)
        let newKernelInfo = try JSONDecoder().decode(KernelInfo.self, from: data)
        try tagDecoder.addKernelInfo(newInfo: newKernelInfo)
        // TODO: check if kernel already exists
        saveNewKernelInfo(at: url, name: newKernelInfo.name)
        Task { @MainActor in
            withAnimation {
                tagDecoder.objectWillChange.send()
            }
        }
    }
    
    internal func saveNewKernelInfo(at url: URL, name: String) {
        do {
            if FileManager.default.fileExists(atPath: kernelsDirPath.path) == false {
                try FileManager.default.createDirectory(
                    at: kernelsDirPath,
                    withIntermediateDirectories: false
                )
            }
            
            let newPath = kernelsDirPath
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(for: .json)
            
            try FileManager.default.copyItem(
                at: url,
                to: newPath
            )
            
            kernelFilenames[name] = newPath.lastPathComponent
        } catch {
            // TODO: handle errors
            print(error)
        }
    }
    
    private func pathForKernel(with name: String) -> URL? {
        kernelFilenames[name]
            .map { kernelsDirPath
                .appendingPathComponent($0)
                .appendingPathExtension(for: .json)
            }
    }
    
    internal func removeKernelInfo(with name: String) {
        guard tagDecoder.kernels.contains(name),
              let kernelInfoPath = pathForKernel(with: name),
              FileManager.default.fileExists(atPath: kernelInfoPath.path)
        else {
            // Nothing to delete
            return
        }
        
        do {
            try FileManager.default.removeItem(at: kernelInfoPath)
            tagDecoder.removeKernelInfo(with: name)
            tagDecoder.objectWillChange.send()
        } catch {
            // TODO: handle error
        }
    }
    
}
