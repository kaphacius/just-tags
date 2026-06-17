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
    
    private static let versions: [String: WhatsNewVM] = .init(
        uniqueKeysWithValues: Version.allCases.map { ($0.version, $0.vm) }
    )
    
}

internal enum Version: CaseIterable {
    
    case oneOne
    case oneTwo
    case oneTwoTwo
    case oneTwoThree
    case oneTwoSix
    case oneTwoSeven
    case oneThreeZero


    internal var vm: WhatsNewVM {
        switch self {
        case .oneOne: Self.oneOneVM
        case .oneTwo: Self.oneTwoVM
        case .oneTwoTwo: Self.oneTwoTwoVM
        case .oneTwoThree: Self.oneTwoThreeVM
        case .oneTwoSix: Self.oneTwoSixVM
        case .oneTwoSeven: Self.oneTwoSevenVM
        case .oneThreeZero: Self.oneThreeZeroVM
        }
    }

    internal var version: String {
        switch self {
        case .oneOne: "1.1.0"
        case .oneTwo: "1.2.0"
        case .oneTwoTwo: "1.2.2"
        case .oneTwoThree: "1.2.3"
        case .oneTwoSix: "1.2.6"
        case .oneTwoSeven: "1.2.7"
        case .oneThreeZero: "1.3.0"
        }
    }
    
    private static let oneOneVM: WhatsNewVM = .init(
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
                description: "Add custom kernel info in Settings to be used during tag parsing."
            ),
            .init(
                iconName: "books.vertical.fill",
                title: "Custom tag mappings",
                description: "Add custom tag mapping in Settings to be used during tag parsing."
            )
        ]
    )
    
    private static let oneTwoVM: WhatsNewVM = .init(
        version: "1.2.0",
        items: [
            .init(
                iconName: "magnifyingglass.circle.fill",
                title: "Tag Library",
                description: "Look up any tag in the Tag Library based on name, description, hex value etc."
            ),
            .init(
                iconName: "text.book.closed.fill",
                title: "Improved tag decoding",
                description: "Added decoding for new tags, including 9F66, 9F40, 95, 9F1D, DFC001 among others."
            )
        ]
    )
    
    private static let oneTwoTwoVM: WhatsNewVM = .init(
        version: "1.2.2",
        items: [
            .init(
                iconName: "magnifyingglass.circle.fill",
                title: "Tag Library",
                description: "Look up any tag in the Tag Library based on name, description, hex value etc."
            ),
            .init(
                iconName: "text.book.closed.fill",
                title: "Improved tag decoding",
                description: "Added decoding for new tags, including 82, 9B."
            )
        ]
    )
    
    private static let oneTwoThreeVM: WhatsNewVM = .init(
        version: "1.2.3",
        items: [
            .init(
                iconName: "magnifyingglass.circle.fill",
                title: "DOL Visualization",
                description: "Parsed DOLs display a list of requested tags."
            ),
            .init(
                iconName: "text.book.closed.fill",
                title: "Improved tag decoding",
                description: "Added decoding for new tags: DF8117, DF811B, 9F6C, 9F07, 9F34."
            ),
            .init(
                iconName: "wand.and.stars.inverse",
                title: "General fixes and improvements",
                description: "Fixed a number of issues around usability and stability."
            )
        ]
    )
    
    private static let oneTwoSixVM: WhatsNewVM = .init(
        version: "1.2.6",
        items: [
            .init(
                iconName: "text.book.closed.fill",
                title: "Improved tag decoding",
                description: "Added decoding for new tags: 8A."
            ),
            .init(
                iconName: "trash.fill",
                title: "Tag removal",
                description: "Added ability to remove tags from the list."
            ),
            .init(
                iconName: "wand.and.sparkles.inverse",
                title: "Custom URL scheme",
                description: "Open the app using custom url scheme justtags://"
            )
        ]
    )
    
    private static let oneThreeZeroVM: WhatsNewVM = .init(
        version: "1.3.0",
        items: [
            .init(
                iconName: "pencil.circle.fill",
                title: "Tag editing",
                description: "Edit tag values directly in the list — toggle individual bits, pick from known value mappings, or type an ASCII string. Edited tags are highlighted so you can track what's changed."
            ),
            .init(
                iconName: "plus.circle.fill",
                title: "Tag and subtag creation",
                description: "Add new tags to the list, or add subtags inside a constructed tag."
            ),
            .init(
                iconName: "rectangle.on.rectangle.fill",
                title: "Open tag in new window",
                description: "Right-click any tag to open it in a new window for focused inspection."
            ),
            .init(
                iconName: "cpu.fill",
                title: "Automatic kernel selection",
                description: "JustTags now detects AID and Kernel ID tags in your data and automatically activates the matching kernel."
            ),
            .init(
                iconName: "text.book.closed.fill",
                title: "Improved tag decoding",
                description: "Added bit-level decoding for many Kernel 2, 4, and 5 tags, plus new decodings for 5F30 Service Code, 5F57 Account Type, 9F2A Kernel Identifier, and more."
            )
        ]
    )

    private static let oneTwoSevenVM: WhatsNewVM = .init(
        version: "1.2.7",
        items: [
            .init(
                iconName: "text.book.closed.fill",
                title: "Improved tag decoding",
                description: "Added decoding for new tags: 9F53."
            ),
            .init(
                iconName: "wand.and.stars.inverse",
                title: "General fixes and improvements",
                description: "Fixed a number of issues around usability and stability."
            )
        ]
    )
    
}
