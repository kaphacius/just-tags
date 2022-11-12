//
//  CustomResource.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 12/11/2022.
//

import Foundation

protocol CustomResource: Decodable {
    
    static var folderName: String { get }
    static var iconName: String { get }
    static var settingsPage: String { get }
    static var displayName: String { get }
    
    var identifier: String { get }
    
}

protocol CustomResourceHandler {
    
    associatedtype Resource: CustomResource
    
    func addCustomResource(_ resource: Resource) throws
    func removeCustomResource(with identifier: String) throws
    var identifiers: [String] { get }
    
}
