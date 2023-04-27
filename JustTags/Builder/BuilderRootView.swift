//
//  BuilderRootView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 28/02/2023.
//

import SwiftUI

struct BuilderRootView: View {
    
    @ObservedObject internal var vm: BuilderRootVM
    
    var body: some View {
        HStack(alignment: .top, spacing: 0.0) {
            VStack(spacing: 0.0) {
                textField
                ScrollView {
                    BuilderByteList(bytes: $vm.bytes)
                        .padding(commonPadding)
                        .padding(.trailing, -commonPadding)
//                        .frame(minWidth: 280.0)
                }
            }
            .frame(minWidth: 280.0)
            .padding([.top, .leading], commonPadding)
            if let tag = vm.decodedTag {
                TagDetailsView(vm: tag.tagDetailsVMs[0])
                    .frame(minWidth: detailWidth)
            }
        }
    }
    
    @ViewBuilder
    private var textField: some View {
        GroupBox {
            BuilderTextField(text: $vm.text)
        }
    }
}

struct BuilderRootView_Previews: PreviewProvider {
    static var previews: some View {
        BuilderRootView(
            vm: .init(
                tagDecoder: AppVM.shared.tagDecoder,
                decodedTag: .mockTag
            )
        ).frame(width: 1000, height: 1200)
    }
}
