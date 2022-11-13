//
//  CustomResource.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 12/11/2022.
//

import Foundation
import SwiftUI

protocol CustomResource: Decodable, Identifiable, Comparable {
    
    static var folderName: String { get }
    static var iconName: String { get }
    static var settingsPage: String { get }
    static var displayName: String { get }
    
    var id: ID { get }
    
}

protocol CustomResourceHandler {
    
    associatedtype Resource: CustomResource
    
    func addCustomResource(_ resource: Resource) throws
    func removeCustomResource(with id: Resource.ID) throws
    var identifiers: [Resource.ID] { get }
    var resources: [Resource] { get }
    
}

protocol CustomResourceView: View {
    
    associatedtype Resource: CustomResource
    
    init(resource: Resource)
    
}
