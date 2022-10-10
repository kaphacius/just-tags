//
//  DecodedRowView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 10/10/2022.
//

import SwiftUI

struct DecodedRowVM: Equatable {
    
    internal let meaning: String
    internal let isSelected: Bool
    internal let values: [String]
    internal let startIndex: Int
    
}

struct DecodedRowView: View {
    
    private static let rowHeight = 25.0
    private static let borderColor: Color = Color(nsColor: .tertiaryLabelColor)
    
    internal let vm: DecodedRowVM
    
    var body: some View {
        HStack(spacing: 0.0) {
            ForEach(0..<8, id: \.self, content: element(for:))
            meaningView
        }
        .frame(height: Self.rowHeight)
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
        .border(Self.borderColor, width: 0.5)
    }
    
    @ViewBuilder
    private func element(for idx: Int) -> some View {
        Group {
            if idx < vm.startIndex {
                emptyElement
            } else {
                valueElement(with: vm.values[idx - vm.startIndex])
            }
        }.frame(width: Self.rowHeight, height: Self.rowHeight)
    }
    
    private var emptyElement: some View {
        Rectangle()
    }
    
    private func valueElement(with text: String) -> some View {
        Rectangle()
            .foregroundColor(.clear)
            .border(Self.borderColor, width: 0.5)
            .overlay {
                Text(text)
            }
    }
    
}

struct DecodedRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            DecodedRowView(
                vm: .init(
                    meaning: "Set Offline Counters to Upper Offline Limits",
                    isSelected: false,
                    values: ["0", "1"],
                    startIndex: 6
                )
            )
            DecodedRowView(
                vm: .init(
                    meaning: "Set Offline Counters to Upper Offline Limits",
                    isSelected: true,
                    values: ["0", "1"],
                    startIndex: 6
                )
            )
        }
    }
}
