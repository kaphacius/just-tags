//
//  TagListView.swift
//  BERTLVEMV
//
//  Created by Yurii Zadoianchuk on 10/03/2022.
//

import SwiftUI
import Combine
import SwiftyEMVTags

let commonPadding: CGFloat = 4.0
let detailWidth: CGFloat = 500.0

internal struct TagListView: View {

    @Binding internal var tags: [TagRowVM]
    @Binding internal var searchInProgress: Bool
    @Environment(\.isSearching) internal var isSearching
    
    internal var body: some View {
        VStack(spacing: commonPadding) {
            ScrollView {
                tagList
            }
        }
        .frame(maxWidth: .infinity)
        .padding([.top, .leading, .bottom], commonPadding)
        .onChange(of: isSearching) { newValue in
            searchInProgress = newValue
        }
    }
    
    private var tagList: some View {
        LazyVStack(spacing: commonPadding) {
            ForEach(tags, content: TagRowView.init(vm:))
        }
        .animation(.linear(duration: 0.1), value: tags)
    }
    
}

struct EMVTagListView_Previews: PreviewProvider {
    static var previews: some View {
        TagListView(
            tags: .constant(
                [.mockTag, .mockTagExtended, .mockTagConstructed]
                    .map(TagRowVM.make(with:))
            ), searchInProgress: .constant(true)
        ).environmentObject(MainVM())
    }
}
