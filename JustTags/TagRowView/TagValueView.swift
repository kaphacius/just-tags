//
//  TagValueView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 03/09/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct TagValueVM: Equatable {
    let value: String
    let extendedDescription: String?
}

internal struct TagValueView: View {
    internal let vm: TagValueVM
    
    internal var body: some View {
        HStack(spacing: commonPadding * 2) {
            // WWDC 2024
            // Why is the string split between D and F
            Text(vm.value)
                .font(.title3.monospaced())
            if let extendedDescription = vm.extendedDescription {
                Text(extendedDescription)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TagValueView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TagValueView(vm: EMVTag.mockTag.tagValueVM)
            TagValueView(vm: EMVTag.mockTagExtended.tagValueVM)
        }
    }
}
