//
//  BuilderRootVM.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 28/02/2023.
//

import Foundation
import SwiftyBERTLV
import SwiftyEMVTags
import Combine
import SwiftUI

final class BuilderRootVM: ObservableObject {
    
    @Published internal var decodedTag: EMVTag?
    @Published internal var bytes: [UInt8]
    
    private let tagDecoder: AnyTagDecoder
    private var cancellables: Set<AnyCancellable> = []

    internal init(
        tagDecoder: AnyTagDecoder,
        decodedTag: EMVTag?
    ) {
        self.tagDecoder = tagDecoder
        self.decodedTag = decodedTag
        if let decodedTag {
            self.bytes = decodedTag.tag.value
        } else {
            self.bytes = []
        }
        
        _bytes.projectedValue
            .receive(on: DispatchQueue.global())
            .map { newBytes in
                guard let decodedTag else { return nil }
//                            let hexString = decodedTag.tag.tag.hexString +
//                            decodedTag.tag.lengthBytes.hexString +
//                            newBytes.hexString
                            let hexString = "9F3303\(newBytes.hexString)"
                let newTLV = try! BERTLV.parse(bytes: [0x9f, 0x33, 0x03] + newBytes).first!
                return try! tagDecoder.decodeBERTLV(newTLV)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.decodedTag, on: self)
            .store(in: &cancellables)
//            .sink { newBytes in
//            guard let decodedTag else { return }
////            let hexString = decodedTag.tag.tag.hexString +
////            decodedTag.tag.lengthBytes.hexString +
////            newBytes.hexString
////            let hexString = "9F3303\(newBytes.hexString)"
//            let newTLV = try! BERTLV.parse(bytes: [0x9f, 0x33, 0x03] + newBytes).first!
//            self.decodedTag = try! tagDecoder.decodeBERTLV(newTLV)
//        }.store(in: &cancellables)
    }
    
}
