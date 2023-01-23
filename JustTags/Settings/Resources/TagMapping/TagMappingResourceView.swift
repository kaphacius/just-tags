//
//  TagMappingView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 12/11/2022.
//

import SwiftUI
import SwiftyEMVTags

struct TagMappingResourceVM {
    
    internal let tag: String
    internal let kernel: String
    internal let description: String
    
}

extension TagMapping {
    
    var tagMappingResourceVM: TagMappingResourceVM {
        .init(
            tag: tag.hexString,
            kernel: kernel,
            description: description
        )
    }
    
}

struct TagMappingResourceView: CustomResourceView {
    
    typealias Resource = TagMapping
    
    private let vm: TagMappingResourceVM
    
    init(vm: TagMappingResourceVM) {
        self.vm = vm
    }
    
    init(resource: TagMapping) {
        self.init(vm: resource.tagMappingResourceVM)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: commonPadding) {
                Text(vm.tag)
                    .font(.title2)
                    .bold()
                Text("Kernel: ").bold() + Text(vm.kernel)
                    .italic()
                    .foregroundColor(.secondary)
                Text(vm.description)
            }
        }
    }
}

struct TagMappingView_Previews: PreviewProvider {
    static var previews: some View {
        TagMappingResourceView(
            vm: .init(
                tag: "9F33",
                kernel: "general",
                description: "This is a very long description about something incredibly related to EMV tags."
            )
        ).frame(width: 600.0)
    }
}
