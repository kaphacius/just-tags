//
//  TagHeaderView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 03/09/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct TagHeaderVM: Equatable {
    internal let tag: String
    internal let name: String
}

internal struct TagHeaderView: View {
    internal let vm: TagHeaderVM
    
    internal var body: some View {
        HStack {
            Text(vm.tag)
                .font(.title3.monospaced())
                .fontWeight(.medium)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(vm.name)
                .font(.title3)
                .fontWeight(.regular)
                .minimumScaleFactor(0.5)
        }
    }
}

struct TagHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TagHeaderView(vm: EMVTag.mockTag.tagHeaderVM)
            TagHeaderView(vm: EMVTag.mockTagExtended.tagHeaderVM)
        }
    }
}
