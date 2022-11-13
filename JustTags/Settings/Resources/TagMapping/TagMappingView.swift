//
//  TagMappingView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 12/11/2022.
//

import SwiftUI
import SwiftyEMVTags

struct TagMappingView: CustomResourceView {
    
    typealias Resource = TagMapping
    
    let resource: TagMapping
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: commonPadding) {
                TagValueView(
                    vm: .init(value: resource.tag.hexString, extendedDescription: nil)
                )
            }
        }
    }
}
