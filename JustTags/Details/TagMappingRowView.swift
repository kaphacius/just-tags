//
//  TagMappingRowView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 23/01/2023.
//

import SwiftUI
import SwiftyBERTLV

struct TagMappingRowVM {
    
    internal let value: String
    internal let meaning: String
    internal let tag: BERTLV
    
    internal init?(tag: UInt64, value: String, meaning: String) {
        guard let bytes: [UInt8] = .init(hexString: value) else {
            return nil
        }
        
        self.value = value
        self.meaning = meaning
        self.tag = BERTLV(tag: tag, value: bytes, category: .plain)
    }
    
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
        }.contextMenu(menuItems: contextMenu)
    }
    
    @ViewBuilder
    private func contextMenu() -> some View {
        Button("Copy full tag") {
            NSPasteboard.copyString(vm.tag.bytes.hexString)
        }
        Button("Copy value") {
            NSPasteboard.copyString(vm.value)
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
            )!
        ).frame(width: detailWidth)
        TagMappingRowView(
            vm: .init(
                tag: 0x9F06,
                value: "A0000000033010",
                meaning: "Short"
            )!
        ).frame(width: detailWidth)
    }
}
