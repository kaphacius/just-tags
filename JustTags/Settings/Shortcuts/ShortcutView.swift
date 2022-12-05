//
//  ShortcutView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 05/12/2022.
//

import SwiftUI

struct ShortcutVM: Identifiable {
    
    let id = UUID()
    
    let title: String
    let key: String
    let modifiers: EventModifiers
}

struct ShortcutView: View {
    
    internal let vm: ShortcutVM
    
    var body: some View {
        HStack(spacing: commonPadding) {
            Text(vm.title)
                .font(.title3.weight(.light))
            Spacer()
            
            Group {
                ForEach(
                    vm.modifiers.icons,
                    id: \.self,
                    content: buttonView(for:)
                )
                Text(vm.key)
            }.font(.title3.weight(.medium).monospaced())
        }.padding(.trailing, commonPadding * 2)
    }
    
    func buttonView(for name: String) -> some View {
        Image(systemName: name)
    }
    
    
}

extension EventModifiers {
    
    var icons: [String] {
        var result: [String] = []
        if self.contains(.shift) {
            result.append("shift")
        }
        if self.contains(.command) {
            result.append("command")
        }
        if self.contains(.option) {
            result.append("option")
        }
        if self.contains(.control) {
            result.append("control")
        }
        
        return result.sorted()
    }
    
}

struct ShortcutView_Previews: PreviewProvider {
    static var previews: some View {
        ShortcutView(
            vm: .init(
                title: "Open...",
                key: "O",
                modifiers: [.command]
            )
        )
    }
}
