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
                .font(.largeTitle)
                .padding(.top)
                .padding(.bottom, commonPadding)
            Text("Version \(vm.version)").font(.title2.italic())
                .foregroundStyle(.secondary)
                .padding(.bottom, 30.0)
            
            VStack(alignment: .leading, spacing: 40) {
                ForEach(vm.items, content: itemView(for:))
            }
            .padding(.bottom, 30.0)
            
            
            getStartedButton
                .padding(.bottom, 10.0)
            
            Button(
                "Full Release Notes",
                action: openReleaseNotes
            )
            .buttonStyle(.link)
            
        }

        .padding()
        .frame(width: 400)
    }
    
    private var getStartedButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Get Started")
                .font(.title3)
                .foregroundColor(.white)
                .padding()
                .padding(.horizontal)
                .background(buttonGradient)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: 15.0, style: .continuous))
        .padding(.bottom, 10.0)
    }
    
    private var buttonGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [.blue, .blue.opacity(0.5)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func itemView(for item: UpdateItem) -> some View {
        HStack {
            Image(systemName: item.iconName)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .frame(width: 50.0, height: 50.0)
            VStack(alignment: .leading, spacing: 0.0) {
                Text(item.title)
                    .font(.body.bold())
                Text(item.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct  WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView(vm: .oneOne)
            .frame(width: 400.0)
        WhatsNewView(vm: .oneTwo)
            .frame(width: 400.0)
    }
}
