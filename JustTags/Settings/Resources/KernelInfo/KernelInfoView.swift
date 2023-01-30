//
//  KernelSettingsView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 15/10/2022.
//

import SwiftUI
import SwiftyEMVTags

struct KernelInfoVM {
    
    internal let name: String
    internal let id: String
    internal let type: String
    internal let description: String
    
}

extension KernelInfo {
    
    var kernelInfoVM: KernelInfoVM {
        .init(
            name: name,
            id: id,
            type: category.rawValue,
            description: description
        )
    }
    
}

struct KernelInfoView: CustomResourceView {
    
    typealias Resource = KernelInfo
    
    init(resource: KernelInfo) {
        self.vm = resource.kernelInfoVM
    }
    
    init(vm: KernelInfoVM) {
        self.vm = vm
    }
    
    private let vm: KernelInfoVM
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: commonPadding) {
                Text(vm.name)
                    .font(.title2)
                Text("Identifier: ").bold() + Text(vm.id)
                    .italic()
                    .foregroundColor(.secondary)
                Text("Type: ").bold() + Text(vm.type)
                Text(vm.description)
            }
        }
    }
}

struct KernelSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        KernelInfoView(
            vm: .init(
                name: "Kernel 2",
                id: "kernel2",
                type: "Scheme",
                description: "EMVco C-2 Kernel 2 for MasterCards AIDs"
            )
        )
    }
}
