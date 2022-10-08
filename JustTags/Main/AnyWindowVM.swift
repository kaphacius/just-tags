//
//  AnyWindowVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/08/2022.
//

import Foundation
import SwiftUI
import SwiftyEMVTags

internal class AnyWindowVM: ObservableObject {
    
    internal var tagDecoder: TagDecoder?
    internal weak var appVM: AppVM?
    
    @Published internal var title = ""
    @Published internal var showsAlert: Bool = false
    internal var errorTitle: String = ""
    internal var errorMessage: String = ""
    
    internal func setUp() {
        title = AppVM.tabName
    }
    
    internal func parse(string: String) {
        assertionFailure("this should be overriden")
    }
    
    internal func tagsByParsing(string: String) -> [EMVTag] {
        do {
            guard let tagDecoder = tagDecoder else {
                assertionFailure("tagDecoder is missing")
                return []
            }
            
            return try InputParser.parse(input: string)
                .map(tagDecoder.decodeBERTLV(_:))
        } catch {
            showParsingAlert(with: error)
            return []
        }
    }
    
    internal func refreshState() { }
    
    internal func diffSelectedTags() { }
    
    internal func showParsingAlert(with error: Error) {
        showsAlert = true
        errorTitle = "Error parsing tags"
        errorMessage = "Unable to parse given string into BERTLV with error: \(error)"
    }
    
    internal func showTooManyDiffAlert() {
        showsAlert = true
        errorTitle = "Unable to diff selected tags"
        errorMessage = "Diffing is only available if there are 2 tags selected in the current tab. Please select less tags."
    }
    
    internal func showNotEnoughDiffAlert() {
        showsAlert = true
        errorTitle = "Unable to diff selected tags"
        errorMessage = "Diffing is only available if there are 2 tags selected in the current tab. Please select more tags."
    }
    
    internal var isEmpty: Bool {
        false
    }
    
    internal var canPaste: Bool {
        true
    }
    
}
