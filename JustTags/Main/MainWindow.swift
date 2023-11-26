//
//  MainWindow.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 26/11/2023.
//

import SwiftUI

struct MainWindow<Provider: MainVMProvider>: View {
    
    @ObservedObject var vmProvider: Provider
    @Binding var vmId: MainVM.ID
    
    var body: some View {
        if let vm = vmProvider[vm: vmId] {
            MainView(vm: vm)
        } else {
            // We really should not be here
            Text("Something went wrong")
                .font(.largeTitle)
        }
    }
    
}
