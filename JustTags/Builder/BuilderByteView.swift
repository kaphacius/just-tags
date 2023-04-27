//
//  BuilderByteView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 24/02/2023.
//

import SwiftUI
import SwiftyBERTLV

internal struct BuilderByteView: View {
    
    @Binding var byte: UInt8

    var body: some View {
        let byteBits = byte.bits
        let byteHexDigits = byte.hexDigits
        
        HStack {
            nibble(
                nibbleBits: Array(byteBits[0..<4]),
                hexDigit: byteHexDigits[0],
                startIdx: 0
            )
            nibble(
                nibbleBits: Array(byteBits[4..<8]),
                hexDigit: byteHexDigits[1],
                startIdx: 4
            )
        }
    }
    
    @ViewBuilder
    private func bits(_ bits: [UInt8], startIdx: Int) -> some View {
        HStack {
            ForEach(Array(bits.enumerated()), id: \.offset) { (offset, bit) in
                Text(bit == 1 ? "1" : "0")
                    .font(.body.monospaced())
                    .padding(.horizontal, commonPadding * 2)
                    .padding(.vertical, commonPadding / 2)
                    .padding(2)
                    .background(
                        RoundedRectangle(cornerRadius: 5.0)
                            .fill(
                                Color(nsColor: .controlColor)
                                    .gradient
                                    .shadow(.inner(color: .white, radius: 1.0, x: 0, y: 1.75))
                                    .shadow(.inner(color: .white, radius: 1.0, x: 0, y: 1.75))
                                    .shadow(.inner(color: .white, radius: 1.0, x: 0, y: 1.75))
                                    .shadow(.inner(color: .white, radius: 1.0, x: 0, y: 1.75))
                                    .shadow(.inner(color: .white, radius: 1.0, x: 0, y: 1.75))
                                    .shadow(.inner(color: .white, radius: 1.0, x: 0, y: 1.75))
                                    .shadow(.inner(color: .white, radius: 1.0, x: 0, y: 1.75))
                                    .shadow(.inner(color: .white, radius: 1.0, x: 0, y: 1.75))
                            )
                    )
                    .padding(-2)
                    .cornerRadius(5.0)
                    .onTapGesture {
                        onBitFlip(idx: startIdx + offset)
                    }
                    .contentShape(Rectangle())
                    .shadow(color: .black, radius: 1.0, x: 0, y: 2.5)
            }
        }
    }
    
    @ViewBuilder
    private func nibble(nibbleBits: [UInt8], hexDigit: String, startIdx: Int) -> some View {
        GroupBox {
            VStack {
                bits(nibbleBits, startIdx: startIdx)
                Text(hexDigit)
                    .font(.title2.monospaced())
            }
        }
    }
    
    private func onBitFlip(idx: Int) {
        self.byte = self.byte.flippingBit(at: idx)
    }
    
}

extension UInt8 {
    
    var bits: [UInt8] {
        (0..<Self.bitWidth).map { idx in
            (self >> idx) & 0x01
        }.reversed()
    }
    
    var hexDigits: [String] {
        self.hexString.split(by: 1)
    }

    func flippingBit(at idx: Int) -> UInt8 {
        let tidx = Self.bitWidth - 1 - idx
        let mask: UInt8 = 0x01 << tidx
        return self ^ mask
    }
    
}

struct BuilderByteView_Previews: PreviewProvider {
    static var previews: some View {
        BuilderByteView(byte: .constant(0xAB))
    }
}
