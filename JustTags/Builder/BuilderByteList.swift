//
//  BuilderByteList.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 24/02/2023.
//

import SwiftUI

struct BuilderByteList: View {
    
    @Binding var bytes: [UInt8]
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(0..<bytes.count, id: \.self, content: byteView(idx:))
            }
        }
    }
    
    @ViewBuilder
    private func byteView(idx: Int) -> some View {
        GroupBox {
            VStack(spacing: commonPadding) {
                Text("Byte \(idx + 1)")
                    .font(.title).monospaced()
                BuilderByteView(byte: $bytes[idx])
            }
        }
    }
}

struct BuilderByteList_Previews: PreviewProvider {
    static var previews: some View {
        BuilderByteList(bytes: .constant([0xAA, 0xBB, 0xCC]))
    }
}
