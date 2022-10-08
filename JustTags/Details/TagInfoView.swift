//
//  TagInfoView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 28/03/2022.
//

import SwiftUI
import SwiftyEMVTags
import SwiftyBERTLV

struct TagInfoView: View {
    
    internal let vm: TagDetailVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
//            Text(vm.description)
//            Text("Source: ").bold() + Text(vm.source)
//            Text("Format: ").bold() + Text(vm.format)
//            Text("Kernel: ").bold() + Text(vm.kernel)
        }
        .font(.body)
        .padding(commonPadding)
    }
}

//struct MockDataSource: AnyEMVTagInfoSource {
//    
//    func info(for tag: UInt64, kernel: EMVTag.Kernel) -> EMVTag.Info {
//        .init(
//            tag: tag,
//            name: "Mock Very Long name",
//            description: "Indicates the card data input, CVM, and security capabilities of the Terminal and Reader. The CVM capability (Byte 2) is instantiated with values depending on the transaction amount. The Terminal Capabilities is coded according to Annex A.2 of [EMV Book 4].",
//            source: .card,
//            format: "binary",
//            kernel: .general,
//            minLength: "5",
//            maxLength: "5",
//            byteMeaningList: [
//                [
//                    "Manual key entry supported",
//                    "Magnetic stripe supported",
//                    "IC with contacts supported",
//                    "RFU",
//                    "RFU",
//                    "RFU",
//                    "RFU",
//                    "RFU"
//                ],
//                [
//                    "Plaintext PIN for ICC verification",
//                    "Enciphered PIN for online verification",
//                    "Signature (paper)",
//                    "Enciphered PIN for offline verification",
//                    "No CVM Required",
//                    "RFU",
//                    "RFU",
//                    "RFU"
//                ],
//                [
//                    "SDA",
//                    "DDA",
//                    "Card capture",
//                    "RFU",
//                    "CDA",
//                    "RFU",
//                    "RFU",
//                    "RFU"
//                ]
//            ]
//        )
//    }
//    
//}
//
//let mockTLV: BERTLV = try! .parse(bytes: [0x9F, 0x33, 0x03, 0x6A, 0x28, 0xC8]).first!
//let mockInfo: EMVTag.Info = .init(
//    tag: mockTLV.tag,
//    name: "Mock Very Long name",
//    description: "Indicates the card data input, CVM, and security capabilities of the Terminal and Reader. The CVM capability (Byte 2) is instantiated with values depending on the transaction amount. The Terminal Capabilities is coded according to Annex A.2 of [EMV Book 4].",
//    source: .card,
//    format: "binary",
//    kernel: .general,
//    minLength: "5",
//    maxLength: "5",
//    byteMeaningList: [
//        [
//            "Manual key entry supported",
//            "Magnetic stripe supported",
//            "IC with contacts supported",
//            "RFU",
//            "RFU",
//            "RFU",
//            "RFU",
//            "RFU"
//        ],
//        [
//            "Plaintext PIN for ICC verification",
//            "Enciphered PIN for online verification",
//            "Signature (paper)",
//            "Enciphered PIN for offline verification",
//            "No CVM Required",
//            "RFU",
//            "RFU",
//            "RFU"
//        ],
//        [
//            "SDA",
//            "DDA",
//            "Card capture",
//            "RFU",
//            "CDA",
//            "RFU",
//            "RFU",
//            "RFU"
//        ]
//    ]
//)
//let mockDataSource = MockDataSource()
//
//struct TagInfoView_Previews: PreviewProvider {
//    static var previews: some View {
//        TagInfoView(vm:
//                .init(emvTag: EMVTag(tlv: mockTLV, info: mockInfo, subtags: []))
//        )
//    }
//}
