//
//  BuilderTextField.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/04/2023.
//

import SwiftUI

struct BuilderTextField: View {
    
    @Binding internal var text: String
    @FocusState var isFocused: Bool
    
    var body: some View {
        TextField("Hex string", text: $text)
            .font(.system(size: 50).monospaced())
            .focusable(false)
            .textFieldStyle(.plain)
            .padding(commonPadding)
    }
}

struct BuilderTextField_Previews: PreviewProvider {
    static var previews: some View {
        BuilderTextField(text: .constant("9F33032808C8"))
            .padding()
    }
}
