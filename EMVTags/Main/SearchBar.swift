//
//  SearchBar.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 30/03/2022.
//

import SwiftUI

internal struct SearchBar: View {
    
    @Binding var searchText: String
    @FocusState var focused: Bool
    
    internal var body: some View {
        GroupBox {
            ZStack {
                Rectangle()
                    .foregroundColor(Color("LightGray"))
                HStack(spacing: commonPadding) {
                    Image(systemName: "magnifyingglass")
                    TextField("Search...", text: $searchText)
                        .focused($focused)
                        .textFieldStyle(.roundedBorder)
                }
                .foregroundColor(.gray)
                .padding(.leading, commonPadding)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
