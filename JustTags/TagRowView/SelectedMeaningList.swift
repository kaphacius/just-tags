//
//  SelectedMeaningList.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 02/05/2022.
//

import SwiftUI
import SwiftyEMVTags

struct SelectedMeaningList: View {
    
    internal let tag: EMVTag
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: commonPadding) {
//                ForEach(Array(tag.decodedMeaningList
//                    .flatMap(\.bitList)
//                    .filter(\.isSet)
//                    .map(\.meaning)
//                    .enumerated()), id: \.0) { (idx, line) in
//                        Text(line)
//                            .multilineTextAlignment(.leading)
//                    }
            }
            Spacer()
        }
    }
}

//struct SelectedMeaningList_Previews: PreviewProvider {
//    static var previews: some View {
//        SelectedMeaningList(tag: EMVTag(tlv: mockTLV, info: mockInfo, subtags: []))
//    }
//}
