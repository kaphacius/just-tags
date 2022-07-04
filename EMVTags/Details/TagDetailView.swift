//
//  EMVTagDetailView.swift
//  BERTLVEMV
//
//  Created by Yurii Zadoianchuk on 09/03/2022.
//

import SwiftUI
import SwiftyEMVTags

struct TagDetailView: View {
    
    private static let borderColor: Color = Color(nsColor: .tertiaryLabelColor)
    
    private static let rowHeight = 25.0
    
    internal let vm: TagDetailVM
    
    @State var infoOpen = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: commonPadding) {
                header
                detailsView
                ForEach(vm.bytes, content: byteView(for:))
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, commonPadding)
        }.padding(.trailing, -commonPadding)
    }
    
    private var header: some View {
        GroupBox {
            VStack(spacing: 0.0) {
                Text(vm.tag)
                    .font(.title).monospacedDigit()
                Text(vm.name)
                    .font(.title2)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var detailsView: some View {
        GroupBox {
            DisclosureGroup(
                isExpanded: $infoOpen,
                content: {
                    HStack(spacing: 0.0) {
                        TagInfoView(vm: vm)
                        Spacer()
                    }
                }, label: {
                    Label("Tag Info", systemImage: "info.circle.fill")
                        .font(.headline)
                }
            ).padding(.leading, commonPadding)
        }
        .onTapGesture { infoOpen.toggle() }
    }
    
    func byteView(for vm: TagDetailVM.ByteVM) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 4.0) {
                Text("Byte \(vm.byteIdx + 1)")
                    .font(.title2)
                VStack(spacing: 0.0) {
                    bitHeaderRow
                    ForEach(vm.bits, content: bitRow(for:))
                }        .border(Self.borderColor, width: 1.0)
            }
        }
    }
    
    var bitHeaderRow: some View {
        HStack(spacing: 0.0) {
            ForEach(stride(from: UInt8.bitWidth, through: 1, by: -1).map { $0 }, id: \.self) { idx in
                bitView(with: "b\(idx)")
                    .font(.body.bold())
            }
            HStack(spacing: 0.0) {
                Spacer()
                Text("Meaning")
                    .lineLimit(0)
                    .font(.title3.bold())
                    .minimumScaleFactor(0.5)
                    .padding(.trailing, 8.0)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
            .border(Self.borderColor, width: 0.5)
        }
    }
    
    func bitRow(for vm: TagDetailVM.BitVM) -> some View {
        HStack(spacing: 0.0) {
            ForEach(0..<UInt8.bitWidth, id: \.self) { idx in
                bitView(with: idx == vm.idx ? vm.isSet ? "1" : "0" : nil)
                    .font(.body.monospacedDigit())
            }
            HStack(spacing: 0.0) {
                Spacer()
                Text(vm.meaning)
                    .lineLimit(0)
                    .minimumScaleFactor(0.5)
                    .padding(4.0)
            }
            .frame(maxHeight: .infinity)
            .border(Self.borderColor, width: 0.5)
        }
        .background {
            if vm.isSet {
                Color(nsColor: .yellow.withAlphaComponent(0.1))
            }
        }
    }
    
    func bitView(with text: String?) -> some View {
        Rectangle()
            .foregroundColor(.clear)
            .border(Self.borderColor, width: 0.5)
            .frame(width: Self.rowHeight, height: Self.rowHeight)
            .overlay {
                text.map(Text.init)
            }
    }
}

#if DEBUG
struct MockSource: AnyEMVTagInfoSource {
    
    func info(for tag: UInt64, kernel: EMVTag.Kernel) -> EMVTag.Info {
        .init(
            tag: tag,
            name: "Some capabilities",
            description: "A very long description string, explaining what the tag is used for. A very long description string, explaining what the tag is used for. A very long description string, explaining what the tag is used for",
            source: .kernel,
            format: "binary",
            kernel: .general,
            minLength: "Five",
            maxLength: "Ten",
            byteMeaningList: [[
                "Foo", "Bar", "Baz", "Foo", "Bar", "Baz", "RFU", "FoobazFoobazFoobazFoobaz"
            ]]
        )
    }
    
}

let mockTag = EMVTag(
    tlv: try! .parse(bytes: [0x5A, 0x01, 0xFA]).first!,
    kernel: .general,
    infoSource: MockSource()
)

struct EMVTagDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TagDetailView(vm: .init(emvTag: mockTag))
            .frame(width: 500, height: 600)
    }
}

#endif
