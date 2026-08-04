//
//  TagHeaderView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 03/09/2022.
//

import SwiftUI
import SwiftyEMVTags

internal struct TagHeaderVM: Equatable {

    internal struct Meaning: Equatable {
        internal let name: String
        internal let kernel: String?
    }

    internal let tag: String
    internal let meanings: [Meaning]
    internal let hiddenMeanings: [Meaning]

    internal init(tag: String, meanings: [Meaning], hiddenMeanings: [Meaning] = []) {
        self.tag = tag
        self.meanings = meanings
        self.hiddenMeanings = hiddenMeanings
    }
}

internal struct TagHeaderView: View {
    internal let vm: TagHeaderVM
    @State private var showsHiddenMeanings: Bool = false

    internal var body: some View {
        HStack {
            Text(vm.tag)
                .font(.title3.monospaced())
                .fontWeight(.medium)

            nameLabel

            if vm.hiddenMeanings.isEmpty == false {
                disclosureButton
            }
        }
    }

    @ViewBuilder
    private var nameLabel: some View {
        if vm.meanings.isEmpty {
            Image(systemName: "questionmark.app.dashed")
                .foregroundStyle(.secondary)
                .padding(.leading, -commonPadding)
        } else if vm.meanings.count == 1, let meaning = vm.meanings.first {
            Text(meaning.name)
                .font(.title3.weight(.regular))
                .lineLimit(1)
        } else {
            ForEach(vm.meanings, id: \.kernel) { meaning in
                Text(meaning.name)
                    .font(.title3.weight(.regular))
                    .lineLimit(1)
                if let kernel = meaning.kernel {
                    kernelLabel(for: kernel)
                }
            }
        }
    }

    private var disclosureButton: some View {
        Button {
            showsHiddenMeanings.toggle()
        } label: {
            Label(
                "\(vm.hiddenMeanings.count) other kernel\(vm.hiddenMeanings.count == 1 ? "" : "s") define this tag",
                systemImage: showsHiddenMeanings ? "chevron.up" : "chevron.down"
            )
            .labelStyle(.iconOnly)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help("\(vm.hiddenMeanings.count) other kernel\(vm.hiddenMeanings.count == 1 ? "" : "s") define this tag")
        .popover(isPresented: $showsHiddenMeanings) {
            VStack(alignment: .leading, spacing: commonPadding) {
                ForEach(vm.hiddenMeanings, id: \.kernel) { meaning in
                    HStack {
                        Text(meaning.name)
                        if let kernel = meaning.kernel {
                            kernelLabel(for: kernel)
                        }
                    }
                }
            }
            .padding(commonPadding * 2)
        }
    }

    private func kernelLabel(for kernel: String) -> some View {
        // TODO: make this a button?
        Text(kernel)
            .font(.subheadline.weight(.ultraLight).monospaced())
            .padding(.horizontal, 5.0)
            .padding(.vertical, 2.0)
            .foregroundStyle(.secondary)
            .background { kernelLabelBackground() }
    }
    
    private static let cornerRadius: CGFloat = 6.0
    
    private func kernelLabelBackground() -> some View {
        RoundedRectangle(
            cornerRadius: Self.cornerRadius,
            style: .continuous
        )
        .strokeBorder(.orange.opacity(0.9), lineWidth: 1.0)
        .background {
            RoundedRectangle(
                cornerRadius: Self.cornerRadius,
                style: .continuous
            ).fill(.orange.opacity(0.3))
        }
    }
}

struct TagHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            TagHeaderView(vm: EMVTag.mockTagMultipleKernels.tagHeaderVM())
            TagHeaderView(vm: EMVTag.mockTagExtended.tagHeaderVM())
            TagHeaderView(vm: EMVTag.mockTagConstructed.tagHeaderVM())
        }
    }
}
