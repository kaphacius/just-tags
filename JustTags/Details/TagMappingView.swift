//
//  TagMappingView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 23/01/2023.
//

import SwiftUI

struct TagMappingView: View {
    
    internal let listVMs: [TagMappingRowVM]
    
    var body: some View {
        GroupBox {
            VStack(spacing: commonPadding) {
                Text("Possible values")
                    .font(.title3)
                ForEach(listVMs, id: \.value) { vm in
                    TagMappingRowView(vm: vm)
                        .padding(.horizontal, commonPadding / 2)
                }
            }
        }.padding(commonPadding)
    }
}

struct TagMappingView_Previews: PreviewProvider {
    static var previews: some View {
        TagMappingView(
            listVMs: [
                .init(
                    tag: 0x9F06,
                    value: "A0000000033010",
                    meaning: "VISA Interlink, Visa International VISA Interlink, Visa International VISA Interlink, Visa International VISA Interlink, Visa International"
                )!,
                .init(
                    tag: 0x9F06,
                    value: "A0000000033011",
                    meaning: "VISA Interlink, Visa International VISA Interlink, Visa International VISA Interlink, Visa International VISA Interlink, Visa International"
                )!
            ]
        )
    }
}
