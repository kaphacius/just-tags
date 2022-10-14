//
//  DiffedTagValueView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 03/09/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct DiffedTagValueVM {
    
    internal let text: AttributedString
    
    internal init(
        value: [UInt8],
        results: [DiffResult]
    ) {
        self.text = zip(value, results)
            .map { (byte, result) in
                AttributedString(
                    byte.hexString,
                    attributes: result == .different ? backgroundColorContainer : .init()
                )
            }.reduce(into: AttributedString()) { $0.append($1) }
    }
    
}

internal struct DiffedTagValueView: View {
    
    internal let vm: DiffedTagValueVM
    
    internal var body: some View {
        Text(vm.text)
            .font(.title3.monospaced())
    }
    
}

private var backgroundColorContainer: AttributeContainer {
    var container = AttributeContainer()
    container.backgroundColor = diffBackground
    return container
}

struct DiffedTagValueView_Previews: PreviewProvider {
    static var previews: some View {
        DiffedTagValueView(
            vm: .init(
                value: EMVTag.mockTag.tag.value,
                results: [.different, .equal, .different]
            )
        )
    }
}
