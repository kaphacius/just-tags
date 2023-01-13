//
//  LookupKernelInfoView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 02/01/2023.
//

import SwiftUI
import SwiftyEMVTags
import Combine

struct LookupKernelInfoView: View {
    
    @Binding var selectedTag: TagDecodingInfo?
    @Binding internal var list: [TagDecodingInfo]
    
    var body: some View {
        List(list, id: \.self) { tag in
            GroupBox {
                tagRow(for: tag)
            }.overlay(
                RoundedRectangle(cornerRadius: 4.0, style: .continuous)
                    .strokeBorder(lineWidth: 1.0, antialiased: true)
                    .foregroundColor(selectedTag == tag ? .secondary : .clear)
                    .animation(.easeOut(duration: 0.25), value: selectedTag)
            ).onTapGesture {
                if selectedTag == tag {
                    selectedTag = nil
                } else {
                    selectedTag = tag
                }
            }
            .padding(.top, tag == list.first ? commonPadding : 0.0)
        }
        .padding(.trailing, -commonPadding / 2)
        .listStyle(.plain)
    }
    
    private func tagRow(for tag: TagDecodingInfo) -> some View {
        HStack {
            Text(tag.info.tag.hexString)
                .font(.title2.monospaced())
                .tag(tag)
            Text(tag.info.name)
                .font(.title3)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Text(tag.info.kernel)
                .foregroundStyle(.tertiary)
                .font(.body.italic())
                .padding(.trailing, commonPadding / 2)
        }
    }
    
}

struct LookupKernelInfoView_Previews: PreviewProvider {
    static var previews: some View {
        LookupKernelInfoView(
            selectedTag: .constant(nil),
            list: .constant([])
        )
    }
}
