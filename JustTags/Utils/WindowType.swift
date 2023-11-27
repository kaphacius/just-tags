//
//  WindowType.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 29/04/2023.
//

import Foundation

enum WindowType: Equatable, CustomStringConvertible {
    
    enum Case {
        case main
        case diff
        case library
        
        var id: String {
            switch self {
            case .main: "main"
            case .diff: "diff"
            case .library: "library"
            }
        }
        
        var title: String {
            switch self {
            case .main: "Tag parsing"
            case .diff: "Tag diffing"
            case .library: "Tag library"
            }
        }
    }
    
    case main(MainVM)
    case diff(DiffVM)
    case library
    
    var type: Case {
        switch self {
        case .main: return .main
        case .diff: return .diff
        case .library: return .library
        }
    }
    
    var description: String {
        switch self {
        case .main(let mainVM):
            "Main: \(mainVM.title), parsed tags: \(mainVM.initialTags.count)"
        case .diff(let diffVM):
            "Diff: \(diffVM.title), diffed tags: \(diffVM.initialTags[0].count), \(diffVM.initialTags[1].count)"
        case .library:
            "Library"
        }
    }
    
    static func == (lhs: WindowType, rhs: WindowType) -> Bool {
        switch (lhs, rhs) {
        case let (.main(llhs), .main(rrhs)):
            return llhs === rrhs
        case let (.diff(llhs), .diff(rrhs)):
            return llhs === rrhs
        case (.library, .library):
            return true
        case (.library, _),
            (.diff, _),
            (.main, _):
            return false
        }
    }

}
