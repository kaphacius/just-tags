//
//  Search.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 02/02/2023.
//

import Foundation

extension Set<String> {
    
    internal func asFlattenedSearchComponents() -> Set<String> {
        Set(self.flatMap(\.toFlattenedSearchComponents))
    }
    
}

extension String {
    
    var isSearchComponent: Bool {
        count > 2 || UInt64(self, radix: 16) != nil
    }
    
    var toFlattenedSearchComponents: [String] {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .punctuationCharacters)
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .map(\.localizedLowercase)
            .filter(\.isSearchComponent)
    }
    
}

struct PrioritySearchComponents {
    internal let primary: Set<String>
    internal let secondary: Set<String>
}

struct PrioritySearchResult<P: PrioritySearchable> {
    let bestMatches: [P]
    let more: [P]
}

protocol SimpleSearchable: Comparable, Identifiable {
    
    var searchPair: (id: Self.ID, comps: Set<String>) { get }
    
}

protocol PrioritySearchable: Comparable, Hashable {
    
    var searchPair: (hash: Int, comps: PrioritySearchComponents) { get }
    
}

protocol NestedSearchable: SimpleSearchable {
    
    func filterNested(
        using words: Set<String>,
        components: [Self.ID: Set<String>]
    ) -> Self
    
}

protocol SearchComponentsAware {
    
    var searchComponents: Set<String> { get }
    
}

func filterPrioritySearchable<P: PrioritySearchable>(
    initial: [P],
    allSearchComponents: [Int: PrioritySearchComponents],
    words: Set<String>
) -> PrioritySearchResult<P> {
    // Split the initial list into 2 groups:
    // - group where primary search components match the words
    // - group where secondary components match the words
    let grouped = initial.reduce(
        into: (primary: [MatchPair<P>](), secondary: [P]())
    ) { (result, info) in
        guard let searchComponents = allSearchComponents[info.hashValue] else { return }
        let primaryMatch = words.match(with: searchComponents.primary)
        if primaryMatch.isAnyMatch {
            result.primary.append(
                MatchPair(matchResult: primaryMatch, searchable: info)
            )
        } else {
            let secondaryMathch = words.match(with: searchComponents.secondary)
            if secondaryMathch.isAnyMatch {
                result.secondary.append(info)
            }
        }
    }

    return .init(
        bestMatches: grouped.primary.sorted().map(\.searchable),
        more: grouped.secondary.sorted()
    )
}

func filterSimpleSearchable<S: SimpleSearchable>(
    initial: [S],
    components: [S.ID: Set<String>],
    words: Set<String>
) -> [S] {
    initial.filter { searchable in
        guard let comps = components[searchable.id] else { return false }
        return words.isPartialMatchSubset(of: comps)
    }
}

func filterNestedSearchable<N: NestedSearchable>(
    initial: [N],
    components: [N.ID: Set<String>],
    words: Set<String>
) -> [N] {
    initial.filter { searchable in
        guard let comps = components[searchable.id] else { return false }
        return words.isPartialMatchSubset(of: comps)
    }.map { searchable in
        searchable.filterNested(using: words, components: components)
    }
}

extension Set<String> {
    
    // Checks if all elements are partially contained in rhs
    fileprivate func isPartialMatchSubset(of rhs: Self) -> Bool {
        self.allSatisfy { element in
            rhs.contains(where: { rElement in
                rElement.contains(element)
            })
        }
    }

    // Goes through self, checking whether every element is contained inside `rhs`
    // Element can be either fully matching, or partially matching
    // lhs is small, rhs is big
    fileprivate func match(with rhs: Self) -> MatchResult {
        self.reduce(MatchResult(partial: 0, full: 0)) { (result, word) in
            if rhs.contains(word) {
                return result.bumpingFull()
            } else if rhs.contains(where: { rElement in rElement.hasPrefix(word) }) {
                return result.bumpingPartial()
            } else {
                return result
            }
        }
    }
    
}

fileprivate struct MatchResult: Equatable, Comparable {

    fileprivate let partial: Int
    fileprivate let full: Int
    fileprivate let total: Int
    fileprivate let isAnyMatch: Bool
    
    fileprivate init(partial: Int, full: Int) {
        self.partial = partial
        self.full = full
        self.total = partial + full
        self.isAnyMatch = partial != 0 || full != 0
    }
    
    fileprivate func bumpingFull() -> MatchResult {
        .init(partial: self.partial, full: self.full + 1)
    }
    
    fileprivate func bumpingPartial() -> MatchResult {
        .init(partial: self.partial + 1, full: self.full)
    }
    
    fileprivate static func < (lhs: MatchResult, rhs: MatchResult) -> Bool {
        switch (lhs.isAnyMatch, rhs.isAnyMatch) {
        case (false, false):
            // No mtaches - not important
            return true
        case (false, true):
            // Only rhs has matches - rhs comes first
            return false
        case (true, false):
            // Only lhs has matches - lhs comes first
            return true
        case (true, true) where lhs.total != rhs.total:
            // whichever has more total matches comes first
            return lhs.total > rhs.total
        case (true, true) where lhs.full > rhs.full:
            // Lhs has more full matches - comes first
            return true
        case (true, true) where lhs.full == rhs.full && lhs.partial > rhs.partial:
            // Lhs has more partial matches - comes first
            return true
        case (true, true):
            // In any other case - rhs comes first
            return false
        }
    }
    
}

fileprivate struct MatchPair<P: PrioritySearchable>: Comparable {
    
    fileprivate let matchResult: MatchResult
    fileprivate let searchable: P
    
    fileprivate static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.matchResult == rhs.matchResult {
            return lhs.searchable < rhs.searchable
        } else {
            return lhs.matchResult < rhs.matchResult
        }
    }
    
}

extension Array<Set<String>> {
    func foldToSet() -> Set<String> {
        self.reduce(Set<String>()) { (result, element) in
            result.union(element)
        }
    }
}
