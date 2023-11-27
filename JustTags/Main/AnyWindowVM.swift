//
//  AnyWindowVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/08/2022.
//

import Foundation
import SwiftUI
import SwiftyEMVTags
import Combine

internal class AnyWindowVM: ObservableObject {
    
    @Published internal var title = ""
    @Published internal var alert: PresentableAlert?
    @Published internal var tagParser: TagParser! {
        didSet {
            self.cancellable = tagParser.objectWillChange
                .sink { [weak self] in
                    self?.reparse()
                }
        }
    }
    
    internal var cancellable: AnyCancellable?
    internal weak var appVM: AppVM?
    internal var errorTitle: String = ""
    internal var errorMessage: String = ""
    
    internal init() {
        title = AppVM.tabName
    }
    
    internal func reparse() {
        assertionFailure("this should be overriden")
    }
    
    internal func parse(string: String) {
        assertionFailure("this should be overriden")
    }
    
    internal func tagsByParsing(string: String) -> [EMVTag] {
        do {
            return try InputParser.parse(input: string)
                .map(tagParser.decodeBERTLV)
        } catch {
            showParsingAlert(with: error)
            return []
        }
    }
    
    internal func refreshState() { }
    
    internal func showParsingAlert(with error: Error) {
        self.alert = .init(
            title: "Error parsing tags",
            message: "Unable to parse given string into BERTLV with error: \(error)"
        )
    }
    
    internal func showTooManyDiffAlert() {
        self.alert = .init(
            title: "Unable to diff selected tags",
            message: "Diffing is only available if there are 2 tags selected in the current tab. Please select less tags."
        )
    }
    
    internal func showNotEnoughDiffAlert() {
        self.alert = .init(
            title: "Unable to diff selected tags",
            message: "Diffing is only available if there are 2 tags selected in the current tab. Please select more tags."
        )
    }
    
    internal var isEmpty: Bool {
        false
    }
    
}
