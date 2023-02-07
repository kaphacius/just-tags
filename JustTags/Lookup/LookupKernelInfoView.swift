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
    
    struct Section: Identifiable, Equatable {
        let id = UUID()
        let title: String?
        let items: [TagDecodingInfo]
    }
    
    @Binding var selectedTag: TagDecodingInfo?
    internal let sections: [Section]
    
    var body: some View {
        ScrollView {
            ForEach(sections, content: section(section:))
        }.background(.background)
    }
    
    @ViewBuilder
        private func section(section: Section) -> some View {
        LazyVStack {
            sectionHeader(for: section.title)
            
            ForEach(section.items, id: \.self) { tag in
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
                .padding(.horizontal, commonPadding * 2)
            }
        }
    }
    
    @ViewBuilder
    private func sectionHeader(for title: String?) -> some View {
        if let title {
            sectionTitle(for: title)
        } else {
            Rectangle()
                .frame(height: 0.0)
                .foregroundStyle(.clear)
        }
    }
    
    private func sectionTitle(for title: String) -> some View {
        Text(title)
            .font(.title3.italic())
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, commonPadding * 2)
            .padding(.vertical, commonPadding)
            .background {
                Rectangle().foregroundStyle(.tertiary)
            }
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
            sections: [
                .init(title: "First section", items: []),
                .init(title: "Second section", items: [])
            ]
        )
    }
}
