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
            ForEach(
                Array(zip(
                    ["Source", "Format", "Kernel"],
                    [vm.source, vm.format, vm.kernel]
                )),
                id: \.0.self
            ) {
                line(header: $0.0, text: $0.1)
            }
        }
        .font(.body)
        .padding(commonPadding)
    }
    
    private func line(header: String, text: String) -> some View {
        Text("\(header): ").bold() + Text(text)
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
