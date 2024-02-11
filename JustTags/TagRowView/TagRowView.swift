//
//  TagRowView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 22/04/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct TagRowVM: Equatable, Identifiable {
    
    internal let id: EMVTag.ID
    internal let category: Category
    internal let fullHexString: String
    internal let valueHexString: String
    
    internal enum Category {
        case plain(PlainTagVM)
        case constructed(ConstructedTagVM)
        
        fileprivate var isPlain: Bool {
            switch self {
            case .plain: return true
            case .constructed: return false
            }
        }
        
        static func category(
            with tag: EMVTag
        ) -> Category {
            switch tag.category {
            case .plain:
                return .plain(tag.plainTagVM)
            case .constructed:
                return .constructed(tag.constructedTagVM)
            }
        }
    }
    
    init(
        tag: EMVTag
    ) {
        self.id = tag.id
        self.category = .category(with: tag)
        self.fullHexString = tag.fullHexString
        self.valueHexString = tag.valueHexString
    }
}

extension TagRowVM.Category: Equatable {
    
    internal static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.plain(let llhs), .plain(let rrhs)):
            return llhs == rrhs
        case (.constructed(let llhs), .constructed(let rrhs)):
            return llhs == rrhs
        default:
            return false
        }
    }
    
}

internal struct TagRowView: View {
    
    @EnvironmentObject private var windowVM: MainVM
    @State private var isExpanded: Bool = false
    private let borderThickness: Double
    private let deselectedBorderColor: Color
    
    internal let vm: TagRowVM

    internal init(vm: TagRowVM) {
        self.vm = vm
        self.borderThickness = vm.category.isPlain ? 1.0 : 2.0
        self.deselectedBorderColor = vm.category.isPlain ? .clear : .init(nsColor: .quaternaryLabelColor)
    }
    
    internal var body: some View {
        GroupBox {
            switch vm.category {
            case .constructed(let constructedVM):
                ConstructedTagView(vm: constructedVM)
            case .plain(let plainVM):
                PlainTagView(vm: plainVM)
            }
        }
        .contextMenu { contextMenu }
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 4.0, style: .continuous)
                .strokeBorder(lineWidth: borderThickness, antialiased: true)
                .foregroundColor(windowVM.isTagSelected(id: vm.id) ? .secondary : deselectedBorderColor)
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
            TagRowView(vm: .make(with: .mockTagMultipleKernels))
        }
        .environmentObject(MainVM())
    }
}
