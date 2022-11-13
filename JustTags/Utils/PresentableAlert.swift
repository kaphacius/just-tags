//
//  PresentableAlert.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 13/11/2022.
//

import SwiftUI

struct PresentableAlert: Equatable, Identifiable {
    
    let id = UUID()
    let title: String
    let message: String?
    let dismissButtonTitle: String
    
    init(
        title: String = "An Error!",
        message: String?,
        dismissButtonTitle: String = "I'll do better next time"
    ) {
        self.title = title
        self.message = message
        self.dismissButtonTitle = dismissButtonTitle
    }
    
    init(error: Error) {
        if let error = error as? JustTagsError {
            self.init(title: error.title, message: error.message)
        } else {
            self.init(message: "\(error)")
        }
    }
    
}

extension View {
    func errorAlert(_ alert: Binding<PresentableAlert?>) -> some View {
        self.alert(item: alert) { alert in
            Alert(
                title: Text(alert.title),
                message: alert.message.map(Text.init),
                dismissButton: .default(Text(alert.dismissButtonTitle))
            )
        }
    }
}
