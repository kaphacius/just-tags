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
    
    internal var infoDataSource: EMVTagInfoDataSource?
    internal weak var appVM: AppVM?
    
    @Published internal var title = ""
    @Published internal var selectedTags = [EMVTag]()
    @Published internal var selectedIds = Set<UUID>()
    @Published internal var detailTag: EMVTag? = nil
    @Published internal var showsAlert: Bool = false
    @Published internal var disclosureGroups: [UUID: Bool] = [:]
    @Published internal var showsDetails: Bool = true
    internal var errorTitle: String = ""
    internal var errorMessage: String = ""
    
    internal func setUp() {
        title = AppVM.tabName
    }
    
    internal func contains(id: UUID) -> Bool {
        selectedIds.contains(id)
    }
    
    internal func onTagSelected(tag: EMVTag) {
        if selectedIds.contains(tag.id) {
            selectedIds.remove(tag.id)
            _ = selectedTags
                .firstIndex(of: tag)
                .map{ selectedTags.remove(at: $0) }
        } else {
            selectedIds.insert(tag.id)
            selectedTags.append(tag)
        }
    }
    
    internal func onDetailTagSelected(tag: EMVTag) {
        if detailTag == tag {
            detailTag = nil
        } else {
            detailTag = tag
        }
        showsDetails = true
    }
    
    internal var hexString: String {
        selectedTags.map(\.hexString).joined()
    }
    
    internal func parse(string: String) {
        assertionFailure("this should be overriden")
    }
    
    internal func tagsByParsing(string: String) -> [EMVTag] {
        do {
            guard let infoDataSource = infoDataSource else {
                assertionFailure("infoDataSource is missing")
                return []
            }
            
            let tlv = try InputParser.parse(input: string)
            
            return tlv.map { EMVTag(tlv: $0, kernel: .general, infoSource: infoDataSource) }
        } catch {
            showParsingAlert(with: error)
            return []
        }
    }
    
    internal func refreshState() {
        selectedTags = []
        selectedIds = []
        detailTag = nil
        disclosureGroups = [:]
    }
    
    internal func selectAll() { }
    
    internal func deselectAll() { }
    
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
    
    internal func binding(for uuid: UUID) -> Binding<Bool> {
        .init(
            get: { self.disclosureGroups[uuid, default: false] },
            set: { self.disclosureGroups[uuid] = $0 }
        )
    }
    
}
