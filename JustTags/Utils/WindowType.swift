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
    
    var title: String? {
        switch self {
        case .main(let mainVM): mainVM.title
        case .diff(let diffVM): diffVM.title
        case .library: nil
        }
    }
    
    func update(title: String) {
        switch self {
        case .main(let mainVM):
            mainVM.title = title
        case .diff(let diffVM):
            diffVM.title = title
        case .library:
            // We should not be here
            break
        }
    }
    
    var asMainVM: MainVM? {
        switch self {
        case .main(let mainVM): mainVM
        case .diff: nil
        case .library: nil
        }
    }
    
    static func == (lhs: WindowType, rhs: WindowType) -> Bool {
        switch (lhs, rhs) {
        case let (.main(llhs), .main(rrhs)):
            if llhs === rrhs {
                if llhs.didChange {
                    // If VM changed - need to redraw commands
                    onMain { llhs.didChange = false }
                    // Return false to force redraw
                    return false
                } else {
                    return true
                }
            } else {
                return false
            }
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
