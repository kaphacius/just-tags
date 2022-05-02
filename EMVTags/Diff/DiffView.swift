//
//  DiffView.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 21/04/2022.
//

import SwiftUI
import class AppKit.NSColor
import SwiftyEMVTags

struct DiffView: View {
    
    @EnvironmentObject private var infoDataSource: EMVTagInfoDataSource
    
    @State private var columns: Int
    @State private var texts: [String]
    @State private var initialTags: [[EMVTag]]
    @State private var diffResults: [TagDiffResult]
    @State private var showOnlyDifferent: Bool
    @State private var showsDiff: Bool
    @State private var showsError: Bool = false
    
    internal init(
        columns: Int = 2,
        texts: [String] = ["", ""],
        initialTags: [[EMVTag]] = [],
        diffResults: [TagDiffResult] = []
    ) {
        _columns = .init(initialValue: columns)
        _texts = .init(initialValue: texts)
        _initialTags = .init(initialValue: initialTags)
        _showOnlyDifferent = .init(initialValue: false)
        _diffResults = .init(
            initialValue: Self.diffInput(
                tags: initialTags,
                onlyDifferent: false
            )
        )
        _showsDiff = .init(initialValue: initialTags.count == columns)
    }
    
    var body: some View {
        VStack(spacing: commonPadding) {
            header
            main
                .frame(minWidth: 800.0)
        }
        .onChange(of: showOnlyDifferent) { onlyDifferent in
            diffInitialTags()
        }
        .animation(.none, value: showOnlyDifferent)
        .padding(.horizontal, commonPadding)
        .padding(.top, commonPadding)
        .alert("Error parsing input", isPresented: $showsError, actions: {})
    }
    
    @ViewBuilder var header: some View {
        if showsDiff {
            GroupBox {
                HStack {
                    Toggle("Show only different tags", isOn: $showOnlyDifferent)
                        .background(onlyDiffShortcut)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder var main: some View {
        Group {
            if showsDiff {
                diffTagList(for: diffResults.map(\.diffedPair))
            } else {
                columnsView
            }
        }
    }
    
    @ViewBuilder
    private var onlyDiffShortcut: some View {
        EmptyView().background {
            Button("only diff") {
                showOnlyDifferent.toggle()
                diffInitialTags()
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
            .hidden()
        }
    }
    
    @ViewBuilder
    private var columnsView: some View {
        HStack(spacing: commonPadding) {
            ForEach(0..<columns, id: \.self, content: column(for:))
        }
    }
    
    @ViewBuilder
    private func column(for idx: Int) -> some View {
        GroupBox {
            if showsDiff {
                tagList(for: initialTags[idx])
            } else {
                textInput(for: idx)
            }
        }.frame(minHeight: 500.0)
    }
    
    @ViewBuilder
    private func textInput(for idx: Int) -> some View {
        TextEditor(text: $texts[idx])
            .onChange(of: texts[idx]) { text in
                do {
                    try parseInput(text, at: idx)
                } catch {
                    texts[idx] = ""
                    showsError = true
                }
            }
            .overlay(HintView())
    }
    
    @ViewBuilder
    private func tagList(for tags: [EMVTag]) -> some View {
        ScrollView {
            LazyVStack(spacing: commonPadding) {
                ForEach(tags, content: TagRowView.init(tag:))
            }
        }
        .animation(.linear(duration: 0.5), value: tags)
        .transition(.opacity)
    }
    
    @ViewBuilder
    private func diffTagList(for normalizedDiffs: [DiffedTagPair]) -> some View {
        ScrollView {
            LazyVStack(spacing: commonPadding) {
                ForEach(Array(normalizedDiffs.enumerated()), id: \.0) { (offset, row) in
                    diffTagRowView(for: row)
                }
            }
        }
        .transition(.opacity)
    }
    
    @ViewBuilder
    private func diffTagRowView(for diffPair: DiffedTagPair) -> some View {
        Group {
            switch (diffPair.lhs, diffPair.rhs) {
            case (let lhs?, let rhs?):
                HStack(spacing: commonPadding) {
                    TagRowView(diffedTag: lhs)
                    TagRowView(diffedTag: rhs)
                }
            case (let lhs?, _):
                HStack(spacing: commonPadding) {
                    TagRowView(diffedTag: lhs)
                    Rectangle().hidden()
                }
            case (_, let rhs?):
                HStack(spacing: commonPadding) {
                    Rectangle().hidden()
                    TagRowView(diffedTag: rhs)
                }
            case (nil, nil):
                EmptyView()
            }
        }
        .background {
            if diffPair.isEqual {
                Color.clear
            } else {
                diffBackground
                    .clipShape(RoundedRectangle(cornerRadius: 5.0, style: .continuous))
            }
        }
    }
    
    private func parseInput(_ input: String, at idx: Int) throws {
        let tlv = try InputParser.parse(input: input)
        let tags = tlv
            .map { EMVTag(tlv: $0, kernel: .general, infoSource: infoDataSource) }
            .sortedTags
        
        guard tags.isEmpty == false else { return }
        
        if initialTags.count <= idx {
            initialTags.append(tags)
        } else {
            initialTags[idx] = tags
        }
        
        diffInitialTags()
    }
    
    private func diffInitialTags() {
        if initialTags.count == columns {
            showsDiff = true
        }
        
        diffResults = Self.diffInput(tags: initialTags, onlyDifferent: showOnlyDifferent)
    }
    
    private static func diffInput(tags: [[EMVTag]], onlyDifferent: Bool) -> [TagDiffResult] {
        guard tags.isEmpty == false else {
            return []
        }
        
        if tags.count == 1 {
            return tags[0].map(TagDiffResult.equal)
        }
        
        let result = diffCompareTags(lhs: tags[0], rhs: tags[1])
        
        if onlyDifferent {
            return result.filter(\.isDifferent)
        }
        
        return result
    }

}

struct DiffView_Previews: PreviewProvider {
    
    static let initialTags = [
        try! InputParser.parse(input: "95 05 00 FF 00 AB 00 9f 5a 05 00 08 40 08 40 8f 01 92 4f 07 a0 00 00 00 03 10 10 50 0b 56 49 53 41 20 43 52 45 44 49 54 82 02 20 20 84 07 a0 00 00 00 03 10 10 95 05 00 00 00 00 00 9a 03 22 03 08 9c 01 00 5f 24 03 24 12 31 5f 2a 02 08 40 5f 34 01 01 9f 02 06 00 00 00 00 20 00 9f 06 07 a0 00 00 00 03 10 10 9f 10 20 1f 22 01 00 90 00 00 00 00 56 49 53 41 4c 33 54 45 53 54 43 41 53 45 00 00 00 00 00 00 00 00 00 9f 1a 02 08 40 9f 1c 08 32 32 39 30 30 30 30 37 9f 21 03 10 49 18 9f 26 08 94 c6 2d 7d 16 52 c7 0e 9f 27 01 40 9f 33 03 60 28 c8 9f 34 03 1f 00 02 9f 35 01 21 9f 36 02 00 02 9f 37 04 2c 2f f0 b0 9f 39 01 07 9f 66 04 32 00 40 00 9f 6e 04 20 70 00 00 9f 7c 0c 01 0a 43 41 52 44 02 44 47 49 91 16 d3 2c 25 42 34 37 36 31 2a 2a 2a 2a 2a 2a 2a 2a 30 30 32 37 5e 20 2f 5e 32 34 31 32 32 30 31 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a d4 28 3b 34 37 36 31 2a 2a 2a 2a 2a 2a 2a 2a 30 30 32 37 3d 32 34 31 32 32 30 31 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a df 81 29 08 10 f0 f0 00 a8 f0 ff 00 c1 02 08 00 c2 01 04 c3 01 02 c4 02 00 00 c5 02 03 01").map { EMVTag(tlv: $0) }
//        try! InputParser.parse(input: "95 05 01 FF 0B AA C0 96 01 AA 9f 5a 05 00 08 40 08 40 8f 01 92 4f 07 a0 00 00 00 03 10 10 82 02 20 20 84 07 a0 00 00 00 03 10 10 95 05 00 00 00 00 00 9a 03 22 03 08 9c 01 00 5f 24 03 24 12 31 5f 2a 02 08 40 5f 34 01 01 9f 02 06 00 00 00 00 20 00 9f 06 07 a0 00 00 00 03 10 10 9f 10 20 1f 22 01 00 90 00 00 00 00 56 49 53 41 4c 33 54 45 53 54 43 41 53 45 00 00 00 00 00 00 00 00 00 9f 1a 02 08 40 9f 1c 08 32 32 39 30 30 30 30 37 9f 21 03 10 49 18 9f 26 08 94 c6 2d 7d 16 52 c7 0e 9f 27 01 40 9f 33 03 60 28 c8 9f 34 03 1f 00 02 9f 35 01 21 9f 36 02 00 02 9f 37 04 2c 2f f0 b0 9f 39 01 07 9f 66 04 32 00 40 00 9f 6e 04 20 70 00 00 9f 7c 0c 01 0a 43 41 52 44 02 44 47 49 91 16 d3 2c 25 42 34 37 36 31 2a 2a 2a 2a 2a 2a 2a 2a 30 30 32 37 5e 20 2f 5e 32 34 31 32 32 30 31 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a d4 28 3b 34 37 36 31 2a 2a 2a 2a 2a 2a 2a 2a 30 30 32 37 3d 32 34 31 32 32 30 31 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a 2a df 81 29 08 10 f0 f0 00 a8 f0 ff 00 c1 02 08 00 c2 01 04 c3 01 02 c4 02 00 00 c5 02 03 02").map { EMVTag(tlv: $0) }
    ]
    static let dataSources = initialTags.map(TagsDataSource.init)
    
    static var previews: some View {
        DiffView(
            initialTags: initialTags
        )
    }
}
