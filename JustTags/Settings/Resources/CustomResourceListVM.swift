//
//  CustomResourceListVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 10/11/2022.
//

import SwiftUI

class CustomResourceListVM<
    R: CustomResource, H: CustomResourceHandler
> : ObservableObject where H.P == R  {
    
    @Published var lines: [String] = []
    
    private let repo: CustomResourceRepo<H>
    
    init(repo: CustomResourceRepo<H>) {
        self.repo = repo
        self.lines = repo.names
    }
    
    internal func addNewResource(at url: URL) throws {
        try repo.addNewResource(at: url)
        self.lines = repo.names
    }
    
    internal func removeResource(with identifier: String) throws {
        try repo.removeResource(with: identifier)
        self.lines = repo.names
    }
    
}
