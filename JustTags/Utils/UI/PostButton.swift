//
//  PostButton.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/11/2023.
//

import SwiftUI

struct PostButtonStyle: PrimitiveButtonStyle {
    public let postAction: (() -> Void)

    public init(postAction: @escaping () -> Void) {
        self.postAction = postAction
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        return Button(role: configuration.role) {
            configuration.trigger()
            postAction()
        } label: {
            configuration.label
        }
    }
}
