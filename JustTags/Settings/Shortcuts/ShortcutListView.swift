//
//  ShortcutListView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 03/12/2022.
//

import SwiftUI

struct ShortcutListView: View {
    
    let lines: [ShortcutVM]
    
    var body: some View {
        ScrollView {
            VStack(spacing: commonPadding) {
                ForEach(lines) { line in
                    GroupBox {
                        ShortcutView(vm: line)
                    }
                }
            }
        }
    }
}

struct ShortcutListView_Previews: PreviewProvider {
    static var previews: some View {
        ShortcutListView(lines: shortcuts)
    }
}
