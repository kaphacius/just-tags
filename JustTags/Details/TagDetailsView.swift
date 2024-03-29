//
//  EMVTagDetailView.swift
//  BERTLVEMV
//
//  Created by Yurii Zadoianchuk on 09/03/2022.
//

import SwiftUI
import SwiftyEMVTags

struct TagDetailsVM {
    
    let tag: String
    let name: String
    let info: TagInfoVM
    let bytes: [DecodedByteVM]
    let kernel: String
    
}

struct TagDetailsView: View {
    
    internal let vm: TagDetailsVM
    
    @State var infoOpen = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: commonPadding) {
            header
            info
            bytes
        }
        .frame(maxWidth: .infinity)
        .padding(commonPadding)
    }
    
    private var header: some View {
        GroupBox {
            VStack(spacing: 0.0) {
                Text(vm.tag).font(.largeTitle.monospaced())
                Text(vm.name).font(.title2)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var info: some View {
        GroupBox {
            DisclosureGroup(
                isExpanded: $infoOpen,
                content: {
                    HStack(spacing: 0.0) {
                        TagInfoView(vm: vm.info)
                        Spacer()
                    }
                }, label: {
                    Label("Tag Info", systemImage: "info.circle.fill")
                        .font(.headline)
                }
            ).padding(.leading, commonPadding)
        }
        .onTapGesture { infoOpen.toggle() }
    }
    
    private var bytes: some View {
        ForEach(vm.bytes, id: \.idx, content: DecodedByteView.init(vm:))
    }
}


struct EMVTagDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TagDetailsView(vm: EMVTag.mockTag.tagDetailsVMs.first!)
            .frame(width: detailWidth, height: 1000)
    }
}
