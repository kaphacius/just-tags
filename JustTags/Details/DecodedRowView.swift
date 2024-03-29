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
    
    @Environment(\.isLibrary) private var isLibrary
    
    private static let rowHeight = 25.0
    private static let borderColor: Color = Color(nsColor: .tertiaryLabelColor)
    
    internal let vm: DecodedRowVM
    
    var body: some View {
        HStack(spacing: 0.0) {
            Group {
                ForEach(
                    (0..<UInt8.bitWidth).map { ($0, vm.value(at: $0)) },
                    id: \.0
                ) {
                    element(with: $0.1)
                }
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
            Text(vm.meaning)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, commonPadding)
                .padding(.vertical, commonPadding / 2.0)
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
                text.map { Text(isLibrary ? lookupSymbol : $0) }
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
        }.frame(width: detailWidth)
    }
}
