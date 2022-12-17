//
//  SelectedMeaningList.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 02/05/2022.
//

import SwiftUI
import SwiftyEMVTags

struct SelectedMeaningList: View {
    
    internal let meanings: [String]
    
    internal var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: commonPadding) {
                ForEach(meanings, id: \.self) { meaning in
                    Text(meaning)
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer()
        }.padding(.bottom, commonPadding)
    }
}

struct SelectedMeaningList_Previews: PreviewProvider {
    static var previews: some View {
        SelectedMeaningList(
            meanings: EMVTag.mockTag.selectedMeanings
        )
    }
}
