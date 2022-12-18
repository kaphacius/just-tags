//
//  DetailsButton.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 18/12/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct DetailsButton: View {
    
    internal var id: EMVTag.ID
    
    @EnvironmentObject private var windowVM: MainVM
    
    var body: some View {
        Button(
            action: {
                windowVM.onDetailTagSelected(id: id)
            }, label: {
                GroupBox {
                    Label("Details", systemImage: buttonImage)
                        .labelStyle(.iconOnly)
                        .padding(.horizontal, commonPadding)
                }
            }
        )
        .padding(.horizontal, commonPadding)
        .buttonStyle(.plain)
    }
    
    private var buttonImage: String {
        windowVM.detailTag?.id == id ? "lessthan" : "greaterthan"
    }
}

struct DetailsButton_Previews: PreviewProvider {
    static var previews: some View {
        DetailsButton(id: .init())
            .environmentObject(MainVM())
    }
}
