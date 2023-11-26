//
//  DiffWindow.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 25/11/2023.
//

import SwiftUI

protocol DiffVMProvider: ObservableObject {
    
    subscript(vm id: DiffVM.ID) -> DiffVM? { get }
    
    func createNewDiffVM() -> DiffVM
    
}

struct DiffWindow<Provider: DiffVMProvider>: View {
    
    @ObservedObject var vmProvider: Provider
    @Binding var vmId: DiffVM.ID
    
    var body: some View {
        if let vm = vmProvider[vm: vmId] {
            DiffView(vm: vm)
        } else {
            // We really should not be here
            Text("Something went wrong")
                .font(.largeTitle)
        }
    }
    
}
