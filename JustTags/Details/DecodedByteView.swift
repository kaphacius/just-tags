//
//  DecodedByteView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 10/10/2022.
//

import SwiftUI
import SwiftyEMVTags

struct DecodedByteVM {
    
    internal let title: String
    internal let rows: [DecodedRowVM]
    internal let idx: Int
    
    internal init(idx: Int, name: String?, rows: [DecodedRowVM]) {
        let name = name.map { ": \($0)" } ?? ""
        self.title = "Byte \(idx + 1)\(name)"
        self.rows = rows
        self.idx = idx
    }
    
}

struct DecodedByteView: View {
    
    private static let rowHeight = 25.0
    private static let borderColor: Color = Color(nsColor: .tertiaryLabelColor)
    private static let bitHeaderValues = stride(from: UInt8.bitWidth, through: 1, by: -1)
        .map { "b\($0)" }
    
    internal let vm: DecodedByteVM
    
    internal var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: commonPadding) {
                Text(vm.title)
                    .font(.title2)
                VStack(spacing: 0.0) {
                    bitHeaderRow
                    ForEach(
                        vm.rows,
                        id:\.startIndex,
                        content: DecodedRowView.init(vm:)
                    )
                }
                .border(Self.borderColor, width: 1.0)
            }
        }
    }
    
    private var bitHeaderRow: some View {
        HStack(spacing: 0.0) {
            ForEach(Self.bitHeaderValues, id: \.self) { text in
                bitView(with: text)
                    .font(.body.bold())
            }
            Text("Meaning")
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .frame(height: Self.rowHeight)
                .border(Self.borderColor, width: 0.5)
        }
    }
    
    private func bitView(with text: String?) -> some View {
        Rectangle()
            .foregroundColor(.clear)
            .border(Self.borderColor, width: 0.5)
            .frame(width: Self.rowHeight, height: Self.rowHeight)
            .overlay {
                text.map(Text.init)
            }
    }
    
}

struct DecodedByteView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: commonPadding) {
            ForEach(
                Array(EMVTag
                    .mockTag
                    .tagDetailsVMs
                    .flatMap(\.bytes)
                ),
                id: \.idx,
                content: DecodedByteView.init(vm:)
            )
        }.padding()
    }
}
