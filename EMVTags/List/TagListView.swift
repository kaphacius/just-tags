//
//  TagListView.swift
//  BERTLVEMV
//
//  Created by Yurii Zadoianchuk on 10/03/2022.
//

import SwiftUI
import Combine
import SwiftyEMVTags

let commonPadding: CGFloat = 4.0
let detailWidth: CGFloat = 500.0

internal struct TagListView: View {
    
    @State private var disclosureGroups: [UUID: Bool] = [:]
    @EnvironmentObject private var dataSource: TagsDataSource
    
    internal var body: some View {
        VStack(spacing: commonPadding) {
            header
            ScrollView {
                tagList
            }
        }
        .frame(maxWidth: .infinity)
        .padding([.top, .leading, .bottom], commonPadding)
        .onChange(of: dataSource.tags) { _ in
            self.updateGroups()
        }
        .onAppear(perform: updateGroups)
    }
    
    private var header: some View {
        GroupBox {
            HStack {
                Button("Expand all") {
                    for key in disclosureGroups.keys {
                        disclosureGroups[key] = true
                    }
                }
                Button("Collapse all") {
                    for key in disclosureGroups.keys {
                        disclosureGroups[key] = false
                    }
                }
                Spacer()
            }
        }
    }
    
    private var tagList: some View {
        LazyVStack(spacing: commonPadding) {
            ForEach(dataSource.tags, content: tagView(for:))
        }
        .animation(.linear(duration: 0.2), value: dataSource.tags)
    }
    
    func updateGroups() {
        disclosureGroups = dataSource
            .tags
            .filter(\.isConstructed)
            .map(\.id).reduce(into: [:], { $0[$1] = true })
    }
    
    @ViewBuilder
    func tagView(for tag: EMVTag) -> some View {
        if tag.isConstructed {
            GroupBox {
                constructedTagView(for: tag)
            }
        } else {
            TagRowView(tag: tag)
        }
    }
    
    func constructedTagView(for tag: EMVTag) -> some View {
        let binding = expandedBinding(for: tag.id)
        
        return VStack(alignment: .leading) {
            disclosureGroup(for: tag, binding: binding)
            constructedTagValueView(for: tag, binding: binding)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            binding.wrappedValue.toggle()
        }
    }
    
    private func disclosureGroup(for tag: EMVTag, binding: Binding<Bool>) -> some View {
        DisclosureGroup(
            isExpanded: binding,
            content: {
                VStack(alignment: .leading, spacing: commonPadding) {
                    ForEach(tag.subtags, content: TagRowView.init(tag:))
                }
                .padding(.top, commonPadding)
            }, label: {
                TagHeaderView(tag: tag)
                    .padding(.leading, commonPadding)
                    .padding(.vertical, -commonPadding)
            }
        ).animation(.none, value: binding.wrappedValue)
    }
    
    @ViewBuilder
    private func constructedTagValueView(for tag: EMVTag, binding: Binding<Bool>) -> some View {
        if binding.wrappedValue == false {
            HStack(spacing: 0.0) {
                TagValueView(value: tag.value)
                    .multilineTextAlignment(.leading)
                    .padding(.top, -commonPadding)
            }
        }
    }
    
    func expandedBinding(for id: UUID) -> Binding<Bool> {
        .init(
            get: { disclosureGroups[id] ?? true },
            set: { disclosureGroups[id] = $0 }
        )
    }
    
}

#if DEBUG

private let mockTags = try! InputParser.parse(input: "5A81c7df810c01029f060aa0000000041010d076129f150260519f160f3130303920202020202020202020209f1a0205289f1c0832313930303031389f090200029f3501229f40056000b0a003df812005fc50bca000df8121050010000000df812205fc50bcf8009f1d009f6d02ffffdf81170120df81180120df81190108df811b01b0df811e0110df811f0108df812306000000002500df812406000009999999df812506000009999999df8126060000000050009f530152df811c020078df811d0102df812c01009f33032808c8e03b5f2a0209785f3601029f150260519f1a0205289f1c0832313930303031389f1e0832313930303031389f33036028c89f3501229f40056000b0a003e406c10400000899e581a7c14995279f5a9f7e428e9f088f4f5056575a8284959a9c5f245f2a5f349f029f039f069f109f129f1a9f269f279f339f349f359f369f379f399f669f6e9f719f7cd3d4df02df8129dfc302c25a95279f5a9f7e428e9f088f4f5056575a8284959a9b9c5f245f2a5f349f029f039f069f079f0d9f0e9f0f9f109f129f1a9f1c9f219f269f279f339f349f359f369f379f399f419f669f6b9f6e9f7cd3d4dcdfdf02df8129dfc302e181ccdf810c01029f0607a00000000410109f150260519f160f3130303920202020202020202020209f1a0205289f1c0832313930303031389f090200029f3501229f40056000b0a003df812005fc50bca000df8121050010000000df812205fc50bcf8009f1d086c7a0000000000009f6d02ffffdf81170160df81180120df81190108df811b0130df811e0110df811f0108df812306000000002500df812406000009999999df812506000009999999df8126060000000050009f530152df811c020078df811d0102df812c0100e181c7df810c01029f060aa0000000041010d076129f150260519f160f3130303920202020202020202020209f1a0205289f1c0832313930303031389f090200029f3501229f40056000b0a003df812005fc50bca000df8121050010000000df812205fc50bcf8009f1d009f6d02ffffdf81170120df81180120df81190108df811b01b0df811e0110df811f0108df812306000000002500df812406000009999999df812506000009999999df8126060000000050009f530152df811c020078df811d0102df812c0100")
    .map(EMVTag.init(tlv:))

struct EMVTagListView_Previews: PreviewProvider {
    static var previews: some View {
        TagListView()
            .environmentObject(TagsDataSource(tags: mockTags))
    }
}
#endif
