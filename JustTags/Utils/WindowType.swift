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
        case builder
        
        var id: String {
            switch self {
            case .main: "main"
            case .diff: "diff"
            case .library: "library"
            case .builder: "builder"
            }
        }
        
        var title: String {
            switch self {
            case .main: "Tag parsing"
            case .diff: "Tag diffing"
            case .library: "Tag library"
            case .builder: "Tag builder"
            }
        }
    }
    
    case main(MainVM)
    case diff(WNS<DiffVM>)
    case library
    case builder
    
    var type: Case {
        switch self {
        case .main: return .main
        case .diff: return .diff
        case .library: return .library
        case .builder: return .builder
        }
    }
    
    var description: String {
        switch self {
        case .main(let mainVM):
            return "Main: \(mainVM.title), parsed tags: \(mainVM.initialTags.count)"
        case .diff(let diffVM):
            guard let diffVM = diffVM.value else { return "VM Missing for \(diffVM.id)" }
            return "Diff: \(diffVM.title), diffed tags: \(diffVM.initialTags[0].count), \(diffVM.initialTags[1].count)"
        case .library:
            return "Library"
        case .builder:
            return "Builder"
        }
    }
    
    var title: String? {
        switch self {
        case .main(let mainVM): mainVM.title
        case .diff(let diffVM): diffVM.value?.title
        case .library: nil
        case .builder: nil
        }
    }
    
    func update(title: String) {
        switch self {
        case .main(let mainVM):
            mainVM.title = title
        case .diff(let diffVM):
            diffVM.value?.title = title
        case .library, .builder:
            // We should not be here
            break
        }
    }
    
    var asMainVM: MainVM? {
        switch self {
        case .main(let mainVM): mainVM
        case .diff: nil
        case .library: nil
        case .builder: nil
        }
    }
    
    var canPaste: Bool {
        switch self {
        case .main(let mainVM): mainVM.canPaste
        case .diff(let diffVM): diffVM.value?.canPaste ?? false
        case .library: false
        case .builder: false
        }
    }
    
    func paste(_ string: String) {
        switch self {
        case .main(let mainVM):
            mainVM.parse(string: string)
        case .diff(let diffVM):
            diffVM.value?.parse(string: string)
        case .library:
            break
        case .builder:
            break
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
        case (.builder, .builder):
            return true
        case (.library, _),
            (.diff, _),
            (.main, _),
            (.builder, _):
            return false
        }
    }

}
