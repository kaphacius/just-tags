//
//  CustomResourceListVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 10/11/2022.
//

import SwiftUI
import SwiftyEMVTags

extension TagDecoder: ObservableObject { }

class CustomResourceListVM<
    Handler: CustomResourceHandler
> : ObservableObject {
    
    @Published var resources: [Handler.Resource]
    
    private let repo: CustomResourceRepo<Handler>
    
    init(repo: CustomResourceRepo<Handler>) {
        self.repo = repo
        self.resources = repo.resources
    }
    
    internal func addNewResource(at url: URL) throws {
        try repo.addNewResource(at: url)
        self.resources = repo.resources
    }
    
    internal func removeResource(with identifier: String) throws {
        try repo.removeResource(with: identifier)
        self.resources = repo.resources
    }
    
    internal func shouldShowDeleteButton(for identifier: String) -> Bool {
        repo.customIdentifiers.contains(identifier)
    }
    
}
