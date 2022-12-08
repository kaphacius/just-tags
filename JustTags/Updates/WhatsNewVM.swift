//
//  WhatsNewVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/11/2022.
//

import Foundation

struct WhatsNewVM {
    
    let version: String
    let items: [UpdateItem]
    
}

extension WhatsNewVM {
    
    static let versions: [String: WhatsNewVM] = [
        "1.1.0": oneOne
    ]
    
    static let oneOne: WhatsNewVM = .init(
        version: "1.1.0",
        items: [
            .init(
                iconName: "wand.and.stars.inverse",
                title: "State restoration",
                description: "Parsed tags will be saved when the app is quit and restored on next launch."
            ),
            .init(
                iconName: "text.book.closed.fill",
                title: "Custom Kernel Info",
                description: "Add custom kernel info in Settings to be used during tag parsing"
            ),
            .init(
                iconName: "books.vertical.fill",
                title: "Custom TagMappings Info",
                description: "Add custom tag mapping in Settings to be used during tag parsing"
            )
        ]
    )
    
}
