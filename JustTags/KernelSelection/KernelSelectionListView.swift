//
//  KernelSelectionListView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 14/11/2022.
//

import SwiftUI

struct KernelSelectionListView: View {
    
    @ObservedObject internal var vm: KernelSelectionListVM
    
    var body: some View {
        VStack(spacing: commonPadding) {
            ForEach(vm.rowVMs) { vm in
                GroupBox {
                    KernelSelectionRow(
                        vm: vm,
                        isSelected: self.vm.isOnBinding(for: vm.id)
                    )
                }
            }
        }.padding(commonPadding)
    }
    
}

struct KernelSelectionListView_Previews: PreviewProvider {
    static var previews: some View {
        KernelSelectionListView(
            vm: .init(
                tagParser: .init(tagDecoder: try! .defaultDecoder())
            )
        )
    }
}
