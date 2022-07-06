//
//  HintView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 30/04/2022.
//

import SwiftUI

struct HintView: View {
    var body: some View {
        VStack {
            Text("Paste your hex or base64 string here")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(nsColor: NSColor.secondaryLabelColor))
                .padding(.bottom)
                .padding(.horizontal, 20.0)
            HStack(alignment: .center) {
                Group {
                    Image(systemName: "command")
                    Text("+")
                        .padding(.bottom, 10.0)
                        .padding(.leading, -5.0)
                    Text("V")
                        .padding(.bottom, 3.0)
                }.font(.system(size: 70.0))
                    .foregroundColor(Color(nsColor: NSColor.secondaryLabelColor))
            }.padding()
        }
        .disabled(true)
        .allowsHitTesting(false)
    }
}

struct HintView_Previews: PreviewProvider {
    static var previews: some View {
        HintView()
    }
}
