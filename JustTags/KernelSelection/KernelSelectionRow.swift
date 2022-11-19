//
//  KernelSelectionRow.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 18/11/2022.
//

import SwiftUI

struct KernelSelectionRowVM: Identifiable {

    internal let id: String
    internal let name: String
    
}

struct KernelSelectionRow: View {
    
    internal let vm: KernelSelectionRowVM
    internal let isSelected: Binding<Bool>
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(vm.name)
                    .minimumScaleFactor(0.75)
                    .font(.body)
                    .lineLimit(1)
                Text(vm.id)
                    .font(.callout.italic())
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("isSelected", isOn: isSelected)
                .labelsHidden()
                .padding(.trailing, commonPadding)
        }.frame(maxWidth: 250.0)
    }
    
}

struct KernelSelectionRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            KernelSelectionRow(vm: .mockShortVM, isSelected: .constant(true))
            KernelSelectionRow(vm: .mockLongVM, isSelected: .constant(false))
        }
    }
}

