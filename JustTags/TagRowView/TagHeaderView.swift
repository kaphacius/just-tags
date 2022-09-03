//
//  TagHeaderView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 03/09/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct TagHeaderView: View {
    internal let tag: EMVTag
    
    internal var body: some View {
        HStack {
            Text(tag.tag.hexString)
                .font(.title3.monospaced())
                .fontWeight(.medium)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            Text(tag.name)
                .font(.title3)
                .fontWeight(.regular)
                .minimumScaleFactor(0.5)
        }
    }
}

struct TagHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        TagHeaderView(tag: mockTag)
    }
}
