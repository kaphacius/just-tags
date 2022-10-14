//
//  DiffedTagRowView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 03/09/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct DiffedTagRowVM {
    
    internal let id: EMVTag.ID
    internal let headerVM: TagHeaderVM
    internal let valueVM: DiffedTagValueVM
    internal let fullHexString: String
    internal let valueHexString: String
    
}

internal struct DiffedTagRowView: View {
    
    internal let vm: DiffedTagRowVM
    
    internal var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: commonPadding) {
                TagHeaderView(vm: vm.headerVM)
                DiffedTagValueView(vm: vm.valueVM)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contextMenu { contextMenu }
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var contextMenu: some View {
        Button("Copy full tag") {
            NSPasteboard.copyString(vm.fullHexString)
        }
        Button("Copy value") {
            NSPasteboard.copyString(vm.valueHexString)
        }
    }
    
}

struct DiffedTagRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DiffedTagRowView(
                vm: DiffedTag(
                    tag: .mockTag, results: [.different, .equal, .different]
                ).diffedTagRowVM
            )
        }.environmentObject(MainVM())
    }
}
