//
//  About.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/08/2022.
//

import Foundation
import AppKit

internal func showAboutApp() {
    NSApplication.shared.orderFrontStandardAboutPanel(
        options: [
            .credits: creditsString,
            .init(rawValue: "Copyright"): "© 2022 YURII ZADOIANCHUK"
        ]
    )
}

private let creditsString: NSAttributedString = {
    let creditsString = NSMutableAttributedString(
        string: "This is a handy app to help you with (almost) all your EMV tag needs.\nClick "
    )
    
    let bug = NSMutableAttributedString(
        string: "here",
        attributes: [.link: "https://github.com/kaphacius/just-tags/issues/new?labels=bug&title=A+minor+bug"]
    )
    creditsString.append(bug)
    
    creditsString.append(.init(string: " if you have spotted a bug, or "))
    
    let enhancement = NSMutableAttributedString(
        string: "here",
        attributes: [.link: "https://github.com/kaphacius/just-tags/issues/new?labels=enhancement&title=A+great+idea"]
    )
    creditsString.append(enhancement)
    
    creditsString.append(.init(string: " if you have a suggestion."))
    
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    paragraphStyle.lineHeightMultiple = 1.3
    
    let totalRange = NSRange(location: 0, length: creditsString.length)
    let font = NSFont.preferredFont(forTextStyle: .body)
    
    creditsString.addAttribute(
        .paragraphStyle,
        value: paragraphStyle,
        range: totalRange
    )
    
    creditsString.addAttribute(
        .font,
        value: font,
        range: totalRange
    )
    
    return creditsString
}()
