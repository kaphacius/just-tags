//
//  DiffedTagValueView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 03/09/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct DiffedTagValueView: View {
    
    internal let text: AttributedString
    
    init(diffedTag: DiffedTag) {
        self.text = diffedTag.textRepresentation
    }
    
    internal var body: some View {
        Text(text)
            .font(.title3.monospaced())
    }
    
}

private var backgroundColorContainer: AttributeContainer {
    var container = AttributeContainer()
    container.backgroundColor = diffBackground
    return container
}

private extension DiffedTag {
    
    var textRepresentation: AttributedString {
        diffedBytes
            .map { diffedByte in
                AttributedString(
                    diffedByte.byte.hexString,
                    attributes: diffedByte.result == .different ? backgroundColorContainer : .init()
                )
            }.reduce(into: AttributedString()) { $0.append($1) }
    }
    
}

struct DiffedTagValueView_Previews: PreviewProvider {
    static var previews: some View {
        DiffedTagValueView(diffedTag: .init(tag: mockTag, results: [.different, .different, .equal]))
    }
}
