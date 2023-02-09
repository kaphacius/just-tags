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

extension WhatsNewVM: Equatable, Comparable {
    
    static func < (lhs: WhatsNewVM, rhs: WhatsNewVM) -> Bool {
        lhs.version < rhs.version
    }
    
}

extension WhatsNewVM {
    
    private func replacingVersion(with newVersion: String) -> WhatsNewVM {
        .init(
            version: newVersion,
            items: self.items
        )
    }
    
    internal static func vm(for version: String) -> WhatsNewVM {
        if let vm = versions[version] {
            return vm
        } else {
            return versions.values.sorted().last!.replacingVersion(with: version)
        }
    }
    
    private static let versions: [String: WhatsNewVM] = [
        "1.1.0": oneOne,
        "1.2.0": oneTwo
    ]
    
    private static let oneOne: WhatsNewVM = .init(
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
    
    private static let oneTwo: WhatsNewVM = .init(
        version: "1.2.0",
        items: [
            .init(
                iconName: "magnifyingglass.circle.fill",
                title: "Tag Lookup",
                description: "Look up any tag in the Tag Library based on name, description, hex value etc"
            ),
            .init(
                iconName: "text.book.closed.fill",
                title: "Improved tag decoding",
                description: "Added decoding for new tags, including 9F66, 9F40, 95, 9F1D, DFC001, DFC002 DFC003"
            )
        ]
    )
    
    internal static var previewVM: WhatsNewVM { .oneOne }
    
}
