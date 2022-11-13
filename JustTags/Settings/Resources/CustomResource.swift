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

    associatedtype View: CustomResourceView where View.Resource == Self
    
}

protocol CustomResourceHandler<Resource, ResourceID> where Resource.ID == ResourceID {
    
    associatedtype Resource: CustomResource
    associatedtype ResourceID: Hashable
    
    func addCustomResource(_ resource: Resource) throws
    func removeCustomResource(with id: ResourceID) throws
    var identifiers: [Resource.ID] { get }
    var resources: [Resource] { get }
    
}

protocol CustomResourceView<Resource>: View {
    
    associatedtype Resource: CustomResource
    
    init(resource: Resource)
    
}
