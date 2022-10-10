//
//  TagInfoView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 28/03/2022.
//

import SwiftUI
import SwiftyEMVTags

struct TagInfoVM {
    
    let source: String
    let format: String
    let kernel: String
    let description: String
    
}

struct TagInfoView: View {
    
    internal let vm: TagInfoVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: commonPadding) {
            Text(vm.description)
            Text("Source: ").bold() + Text(vm.source)
            Text("Format: ").bold() + Text(vm.format)
            Text("Kernel: ").bold() + Text(vm.kernel)
        }
        .font(.body)
        .padding(commonPadding)
    }
    
}


struct TagInfoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ForEach(Array(EMVTag.mockTag.tagInfoVMs.enumerated()), id: \.offset) {
                TagInfoView(vm: $0.element)
            }
        }.frame(width: 400)
    }
}
