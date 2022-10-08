//
//  TagRowView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 22/04/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct TagRowVM: Equatable, Identifiable {
    
    typealias ID = UUID
    
    internal let id: UUID
    internal let category: Category
    internal let fullHexString: String
    internal let valueHexString: String
    
    internal enum Category {
        case primitive(PrimitiveTagVM)
        case constructed(ConstructedTagVM)
        
        static func category(
            with tag: EMVTag,
            id: UUID
        ) -> Category {
            switch tag.category {
            case .plain:
                return .primitive(
                    .make(
                        with: tag,
                        id: id,
                        // TODO: add expansion
                        canExpand: false,
                        showsDetails: tag.isUnknown == false
                    )
                )
            case .constructed(let subtags):
                return .constructed(
                    .init(
                        id: id,
                        tag: tag,
                        subtags: subtags
                    )
                )
            }
        }
    }
    
    init(
        id: UUID,
        tag: EMVTag
    ) {
        self.id = id
        self.category = .category(with: tag, id: id)
        self.fullHexString = tag.fullHexString
        self.valueHexString = tag.valueHexString
    }
    
    static func == (lhs: TagRowVM, rhs: TagRowVM) -> Bool {
        lhs.id == rhs.id
    }
}

internal struct TagRowView: View {
    
    @EnvironmentObject private var windowVM: MainVM
    @State private var isExpanded: Bool = false
    
    internal let vm: TagRowVM

    internal init(vm: TagRowVM) {
        self.vm = vm
    }
    
    internal var body: some View {
        GroupBox {
            switch vm.category {
            case .constructed(let constructedVM):
                ConstructedTagView(vm: constructedVM)
            case .primitive(let primitiveVM):
                PrimitiveTagView(vm: primitiveVM)
            }
        }
        .contextMenu { contextMenu }
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 4.0, style: .continuous)
                .strokeBorder(lineWidth: 1.0, antialiased: true)
                .foregroundColor(windowVM.isTagSelected(id: vm.id) ? .secondary : .clear)
                .animation(.easeOut(duration: 0.25), value: windowVM.isTagSelected(id: vm.id))
        )
    }
    
    @ViewBuilder
    private var contextMenu: some View {
        Button("Copy full tag") {
            NSPasteboard.copyString(vm.fullHexString)
        }
        Button("Copy value") {
            NSPasteboard.copyString(vm.valueHexString)
        }
        if windowVM.selectedTags.count > 1 {
            Button("Copy selected tags") {
                NSPasteboard.copyString(windowVM.hexString)
            }
        }
        if windowVM.selectedTags.count == 2 {
            Button(
                "Diff selected tags",
                action: windowVM.diffSelectedTags
            )
        }
    }

}

struct TagRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TagRowView(vm: .make(with: .mockTag))
            TagRowView(vm: .make(with: .mockTagExtended))
            TagRowView(vm: .make(with: .mockTagConstructed))
        }
        .environmentObject(MainVM())
    }
}
