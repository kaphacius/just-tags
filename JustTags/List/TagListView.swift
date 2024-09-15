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

    internal var tags: [TagRowVM]
    @Binding internal var searchInProgress: Bool
    @Environment(\.isSearching) internal var isSearching
    
    internal var body: some View {
        tagList
            .frame(maxWidth: .infinity)
            .padding([.top, .leading, .bottom], commonPadding)
            .onChange(of: isSearching) { _, newValue in
                searchInProgress = newValue
            }
    }
    
    private var tagList: some View {
        LazyVStack(spacing: commonPadding) {
            ForEach(tags, content: TagRowView.init(vm:))
        }
        .animation(.none, value: tags)
    }
    
}

struct EMVTagListView_Previews: PreviewProvider {
    static var previews: some View {
        TagListView(
            tags: [.mockTag, .mockTagExtended, .mockTagConstructed]
                .map { .init(tag: $0, isSubtag: false) },
            searchInProgress: .constant(true)
        ).environmentObject(MainVM())
    }
}
