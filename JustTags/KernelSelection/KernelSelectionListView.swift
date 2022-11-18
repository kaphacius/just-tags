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
                        isSelected: self.vm.isOnBinding(for: vm.kernelId)
                    )
                }
            }
        }.padding(commonPadding)
    }
    
    @ViewBuilder
    private func kernelRow(for kernel: String) -> some View {
        GroupBox {
            HStack {
                let binding = isOnBinding(for: kernel)
                Text(kernel)
                Toggle("isOn", isOn: binding)
                    .labelsHidden()
            }
        }
    }
    
    private func isOnBinding(for id: String) -> Binding<Bool> {
        .init(
            get: { vm.selectedKernels.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    vm.selectedKernels.insert(id)
                } else {
                    vm.selectedKernels.remove(id)
                }
            }
        )
    }
}

struct KernelSelectionListView_Previews: PreviewProvider {
    static var previews: some View {
        KernelSelectionListView(
            vm: .init(tagDecoder:  try! .defaultDecoder())
        )
    }
}
