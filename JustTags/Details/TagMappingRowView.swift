//
//  TagMappingRowView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 23/01/2023.
//

import SwiftUI

struct TagMappingRowVM {
    
    internal let tag: UInt64
    internal let value: String
    internal let meaning: String
    
}

struct TagMappingRowView: View {
    
    internal let vm: TagMappingRowVM
    
    var body: some View {
        GroupBox {
            HStack(alignment: .top) {
                Text(vm.value)
                    .font(.title2.monospaced())
                Spacer()
                Text(vm.meaning)
                    .multilineTextAlignment(.trailing)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }.contextMenu {  }
    }
    
    @ViewBuilder
    private var contextMenu: some View {
        Button("Copy full tag") {
            // TODO: handle error
//            if let try? tlv = BERTLV(tag: vm.tag, value: <#T##[UInt8]#>, category: <#T##Category#>)
//            NSPasteboard.copyString(vm.fullHexString)
        }
        Button("Copy value") {
//            NSPasteboard.copyString(vm.valueHexString)
        }
    }
}

struct TagMappingRowView_Previews: PreviewProvider {
    static var previews: some View {
        TagMappingRowView(
            vm: .init(
                tag: 0x9F06,
                value: "A0000000033010",
                meaning: "VISA Interlink, Visa International VISA Interlink, Visa International VISA Interlink, Visa International VISA Interlink, Visa International"
            )
        ).frame(width: detailWidth)
        TagMappingRowView(
            vm: .init(
                tag: 0x9F06,
                value: "A0000000033010",
                meaning: "Short"
            )
        ).frame(width: detailWidth)
    }
}
