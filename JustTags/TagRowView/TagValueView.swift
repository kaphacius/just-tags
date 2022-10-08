//
//  TagValueView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 03/09/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct TagValueView: View {
    internal let tag: EMVTag
    
    internal var body: some View {
        HStack(spacing: commonPadding * 2) {
//            Text(tag.value.hexString)
//                .font(.title3.monospaced())
//            if let text = tag.textRepresentation {
//                Text(text)
//                    .font(.title3)
//                    .foregroundColor(.secondary)
//            }
        }
    }
}

//struct TagValueView_Previews: PreviewProvider {
//    static var previews: some View {
//        TagValueView(tag: mockTag)
//    }
//}
