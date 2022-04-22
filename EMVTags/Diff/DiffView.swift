//
//  DiffView.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 21/04/2022.
//

import SwiftUI

struct DiffView: View {
    
    @FocusState var focused
    
    @State var leftText: String = ""
    @State var rightText: String = ""
    
    var body: some View {
        VStack(spacing: commonPadding) {
            header
            HStack(spacing: commonPadding) {
                GroupBox {
                    TextEditor(text: $leftText)
                        .onChange(of: leftText) { text in
                            do {
                                let parsed = try InputParser.parse(input: text)
                                print(parsed.map(\.tag.hexString))
                            } catch {
                                print(error)
                            }
                        }
                }
                GroupBox {
                    TextEditor(text: $rightText)
                        .onChange(of: rightText) { text in
                            do {
                                let parsed = try InputParser.parse(input: text)
                                print(parsed.map(\.tag.hexString))
                            } catch {
                                print(error)
                            }
                        }
                }
            }.frame(minHeight: 500.0, maxHeight: .infinity)
        }.frame(width: 600.0)
    }
    
    @ViewBuilder var header: some View {
        GroupBox {
            Text("Header")
                .frame(maxWidth: .infinity)
        }
    }
}

struct DiffView_Previews: PreviewProvider {
    static var previews: some View {
        DiffView()
    }
}
