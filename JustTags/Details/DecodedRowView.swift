//
//  DecodedRowView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 10/10/2022.
//

import SwiftUI
import SwiftyEMVTags

struct DecodedRowVM: Equatable {
    
    internal let meaning: String
    internal let isSelected: Bool
    internal let values: [String]
    internal let startIndex: Int
    
    internal func value(at idx: Int) -> String? {
        if idx < startIndex || idx >= startIndex + values.count {
            return nil
        } else {
            return values[idx - startIndex]
        }
    }
    
}

internal struct DecodedRowView: View {
    
    private static let rowHeight = 25.0
    private static let borderColor: Color = Color(nsColor: .tertiaryLabelColor)
    
    internal let vm: DecodedRowVM
    
    var body: some View {
        HStack(spacing: 0.0) {
            Group {
                ForEach(
                    (0..<UInt8.bitWidth).map(vm.value(at:)),
                    id: \.self,
                    content: element(with:)
                )
                meaningView
            }
            .frame(height: Self.rowHeight)
        }
        .background {
            if vm.isSelected {
                Color(nsColor: .yellow.withAlphaComponent(0.1))
            }
        }
    }
    
    private var meaningView: some View {
        HStack(spacing: 0.0) {
            Spacer()
            Text(vm.meaning)
                .lineLimit(0)
                .minimumScaleFactor(0.5)
                .padding(4.0)
        }
        .frame(maxHeight: .infinity)
        .border(Self.borderColor, width: 0.5)
    }
    
    private func element(with text: String?) -> some View {
        Rectangle()
            .foregroundColor(.clear)
            .border(Self.borderColor, width: 0.5)
            .frame(width: Self.rowHeight)
            .overlay {
                text.map(Text.init)
            }
    }
    
}

struct DecodedRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0.0) {
            ForEach(
                Array(EMVTag
                    .mockTag
                    .tagDetailsVMs
                    .flatMap(\.bytes)
                    .flatMap(\.rows)
                    .enumerated()
                ), id: \.offset
            ) { DecodedRowView(vm: $0.element) }
        }
    }
}
