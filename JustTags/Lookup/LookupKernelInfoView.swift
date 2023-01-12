//
//  LookupKernelInfoView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 02/01/2023.
//

import SwiftUI
import SwiftyEMVTags
import Combine

extension TagDecodingInfo: Hashable {
    
    public static func == (lhs: TagDecodingInfo, rhs: TagDecodingInfo) -> Bool {
        lhs.info.tag == rhs.info.tag &&
        lhs.info.kernel == rhs.info.kernel &&
        lhs.info.context == rhs.info.context
    }
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.info.tag)
        hasher.combine(self.info.context)
        hasher.combine(self.info.kernel)
    }
    
}

extension TagInfo: Hashable {
    
    public static func == (lhs: TagInfo, rhs: TagInfo) -> Bool {
        lhs.tag == rhs.tag &&
        lhs.kernel == rhs.kernel &&
        lhs.context == rhs.context
    }
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(tag)
        hasher.combine(context)
        hasher.combine(kernel)
    }
    
}

struct LookupKernelInfoView: View {
    
    @Binding var selectedTag: TagDecodingInfo?
    @Binding internal var list: [TagDecodingInfo]
    
    var body: some View {
        List(list, id: \.self, selection: $selectedTag) { tag in
            GroupBox {
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
                }
            }
        }
        .listStyle(.plain)
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
