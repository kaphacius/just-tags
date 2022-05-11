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
        .onChange(of: dataSource.tags) { _ in
            self.updateGroups()
        }.padding([.top, .leading, .bottom], commonPadding)
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
        dataSource
            .tags
            .filter(\.isConstructed)
            .flatMap(\.subtags)
            .filter { $0.name != "Unknown tag" }
            .map(\.id)
            .forEach { disclosureGroups[$0] = false }
        dataSource
            .tags
            .filter { $0.isConstructed == false }
            .filter { $0.name != "Unknown tag" }
            .map(\.id)
            .forEach { disclosureGroups[$0] = false }
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
        
        return VStack {
            DisclosureGroup(
                isExpanded: binding,
                content: {
                    VStack(alignment: .leading, spacing: commonPadding) {
                        ForEach(tag.subtags) { subtag in
                            GroupBox {
                                HStack {
                                    TagRowView(tag: subtag)
                                    Spacer()
                                }.padding(.horizontal, commonPadding)
                            }
                        }
                    }
                    .padding(.top, 4.0)
                }, label: {
                    tagHeaderView(for: tag)
                        .padding(.leading, commonPadding)
                }
            ).animation(.none, value: binding.wrappedValue)
            if binding.wrappedValue == false {
                HStack {
                    tagValueView(for: tag)
                    Spacer()
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            binding.wrappedValue.toggle()
        }
    }
    
    func expandedBinding(for id: UUID) -> Binding<Bool> {
        .init(
            get: { disclosureGroups[id] ?? true },
            set: { disclosureGroups[id] = $0 }
        )
    }
    
    func tagHeaderView(for tag: EMVTag) -> some View {
        HStack {
            Text(tag.tag.hexString)
                .font(.body)
                .fontWeight(.semibold)
            Text(tag.name)
                .font(.body).fontWeight(.semibold)
        }
    }
    
    func tagValueView(for tag: EMVTag) -> some View {
        Text(tag.value.map(\.hexString).joined())
            .font(.body.monospaced()).fontWeight(.light)
    }
    
}

struct EMVTagListView_Previews: PreviewProvider {
    static var previews: some View {
        TagListView()
            .environmentObject(TagsDataSource(tags: []))
    }
}
