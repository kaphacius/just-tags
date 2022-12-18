//
//  UpdateItem.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 27/11/2022.
//

import Foundation

struct UpdateItem: Identifiable, Equatable {
    
    var id: String { title }
    
    let iconName: String
    let title: String
    let description: String
    
}
