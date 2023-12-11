//
//  UpdateView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/11/2022.
//

import SwiftUI

struct WhatsNewView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    internal var vm: WhatsNewVM
    
    var body: some View {
        VStack(spacing: .zero) {
            Text("What's New in JustTags")
                .font(.system(size: 35.0))
                .padding(.top)
                .padding(.bottom, 10.0)
            Text("Version \(vm.version)").font(.title2.italic())
                .foregroundStyle(.secondary)
                .padding(.bottom, 30.0)
            
            VStack(alignment: .leading, spacing: 30) {
                ForEach(vm.items, content: itemView(for:))
            }
            .padding(.bottom, 30.0)
            .padding(.horizontal, 50.0)
            
            Button(
                "Full Release Notes >",
                action: openReleaseNotes
            )
            .buttonStyle(.link)
            .padding(.bottom, 40.0)
            
            getStartedButton
                .padding(.bottom, 15.0)
            
        }

        .padding()
        .frame(width: 500)
    }
    
    private var getStartedButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Continue")
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.horizontal)
                .padding(.horizontal)
                .padding(.vertical, 5.0)
        }.buttonStyle(.borderedProminent)
    }
    
    private func itemView(for item: UpdateItem) -> some View {
        HStack(spacing: 15.0) {
            VStack {
                Image(systemName: item.iconName)
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
                    .frame(width: 50.0, height: 50.0, alignment: .topTrailing)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 0.0) {
                Text(item.title)
                    .font(.body.weight(.bold))
                Text(item.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct  WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView(vm: .oneOne)
            .frame(width: 500)
        WhatsNewView(vm: .oneTwo)
            .frame(width: 500)
    }
}
