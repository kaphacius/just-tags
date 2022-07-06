//
//  TagDetailVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 29/03/2022.
//

import Foundation
import SwiftyEMVTags

struct TagDetailVM {
    
    init(emvTag: EMVTag) {
        self.tag = emvTag.tag.hexString
        self.name = emvTag.name
        self.description = emvTag.description
        self.kernel = emvTag.kernel.description
        self.source = emvTag.source.description
        self.format = emvTag.format
        
        self.bytes = emvTag
            .decodedMeaningList
            .enumerated()
            .map { (byteIdx, byte) in
                ByteVM(
                    byteIdx: byteIdx,
                    bits: byte.bitList.enumerated().map { (bitIdx, bit) in
                        BitVM(
                            meaning: bit.meaning,
                            isSet: bit.isSet,
                            idx: bitIdx
                        )
                    }
                )
            }
    }
    
    let tag: String
    let name: String
    let description: String
    let kernel: String
    let source: String
    let format: String
    let bytes: [ByteVM]
    
    struct ByteVM: Identifiable {
        let byteIdx: Int
        let bits: [BitVM]
        var id: Int { byteIdx }
    }
    
    struct BitVM: Identifiable {
        let meaning: String
        let isSet: Bool
        let idx: Int
        var id: Int { idx }
        
        internal init(
            meaning: String,
            isSet: Bool,
            idx: Int
        ) {
            self.meaning = meaning
            self.isSet = isSet
            self.idx = idx
        }
    }
}
