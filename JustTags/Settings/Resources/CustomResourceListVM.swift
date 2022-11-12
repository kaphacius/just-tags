//
//  CustomResourceListVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 10/11/2022.
//

import SwiftUI
import SwiftyEMVTags
import Combine

class CustomResourceListVM<
    Handler: CustomResourceHandler
> : ObservableObject {
    
    @Published var resources: [Handler.Resource]
    
    private let repo: CustomResourceRepo<Handler>
    
    private var cancellable: AnyCancellable?
    
    init(repo: CustomResourceRepo<Handler>) {
        self.repo = repo
        self.resources = repo.resources
        self.cancellable = repo.$resources.receive(on: RunLoop.main).sink {
            self.resources = $0
        }
    }
    
    internal func addNewResource(at url: URL) throws {
        try repo.addNewResource(at: url)
    }
    
    internal func removeResource(with identifier: String) throws {
        try repo.removeResource(with: identifier)
    }
    
    internal func shouldShowDeleteButton(for identifier: String) -> Bool {
        repo.customIdentifiers.contains(identifier)
    }
    
}
