//
//  ConstructedTagView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 01/06/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct ConstructedTagVM: Equatable {

    let id: UUID
    let tag: String
    let name: String?
    let headerVM: TagHeaderVM
    let valueVM: TagValueVM
    let subtags: [TagRowVM]
    let showsDetails: Bool
    let isEdited: Bool

}

internal struct ConstructedTagView: View {

    @EnvironmentObject private var windowVM: MainVM
    @State private var showsAddSubtag: Bool = false

    internal let vm: ConstructedTagVM

    internal var body: some View {
        let binding = windowVM.expandedBinding(for: vm.id)

        return HStack {
            VStack(alignment: .leading) {
                disclosureGroup(with: binding)
                if binding.wrappedValue == false {
                    HStack(spacing: 0.0) {
                        TagValueView(vm: vm.valueVM)
                            .multilineTextAlignment(.leading)
                            .padding(.top, -commonPadding)
                    }
                }
            }

            addSubtagButton

            if vm.showsDetails && binding.wrappedValue == false {
                DetailsButton(id: vm.id)
            }
        }
        .contentShape(Rectangle())
        .gesture(TapGesture().modifiers(.command).onEnded { _ in
            windowVM.onTagSelected(id: vm.id)
        })
        .onTapGesture {
            binding.wrappedValue.toggle()
        }
    }

    private var addSubtagButton: some View {
        Button { showsAddSubtag = true } label: {
            GroupBox {
                Label("Add subtag", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .padding(.horizontal, commonPadding)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, commonPadding)
        .popover(isPresented: $showsAddSubtag, arrowEdge: .top) {
            AddTagView(title: "Add Subtag") { tagHex, valueHex in
                windowVM.addSubtag(tagHex: tagHex, valueHex: valueHex, toId: vm.id)
                showsAddSubtag = false
            }
            .environmentObject(windowVM)
        }
    }

    private func disclosureGroup(
        with binding: Binding<Bool>
    ) -> some View {
        DisclosureGroup(
            isExpanded: binding,
            content: {
                VStack(alignment: .leading, spacing: commonPadding) {
                    ForEach(vm.subtags, content: TagRowView.init(vm:))
                }
                .padding(.top, commonPadding)
            }, label: {
                HStack(spacing: commonPadding) {
                    if vm.isEdited {
                        Circle()
                            .fill(.orange)
                            .frame(width: 6.0, height: 6.0)
                            .transition(.scale.combined(with: .opacity))
                    }
                    TagHeaderView(vm: vm.headerVM)
                }
                .animation(.spring(duration: 0.3), value: vm.isEdited)
                .padding(.leading, commonPadding)
                .padding(.vertical, -commonPadding)
            }
        )
        .animation(.none, value: binding.wrappedValue)
    }
    
}


struct ConstructedTagView_Previews: PreviewProvider {
    static var previews: some View {
        ConstructedTagView(vm: .make(with: .mockTagConstructed))
            .environmentObject(MainVM())
    }
}
