//
//  DiffView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 21/04/2022.
//

import SwiftUI
import class AppKit.NSColor
import SwiftyEMVTags

struct DiffView: View {
    
    @StateObject private var vm: DiffWindowVM = .init()
    @EnvironmentObject private var appVM: AppVM
    
    @FocusState internal var focusedEditor: Int?
    
    internal var body: some View {
        VStack(spacing: commonPadding) {
            header
            main
        }
        .onChange(of: focusedEditor, perform: vm.updateFocusedEditor)
        .animation(.none, value: vm.showOnlyDifferent)
        .padding(.horizontal, commonPadding)
        .padding(.top, commonPadding)
        .alert(vm.errorTitle, isPresented: $vm.showsAlert, actions: {
            Button("I'll do better next time") {}
        }, message: {
            Text(vm.errorMessage)
        })
        .background {
            HostingWindowFinder { window in
                guard let window = window else { return }
                self.appVM.addWindow(window, viewModel: vm)
            }.opacity(0.0)
        }
        .environmentObject(vm as AnyWindowVM)
        .onAppear(perform: vm.setUp)
        .navigationTitle(vm.title)
    }
    
    @ViewBuilder
    private var header: some View {
        if vm.showsDiff {
            GroupBox {
                HStack {
                    Toggle("Show only different tags", isOn: $vm.showOnlyDifferent)
                        .background(onlyDiffShortcut)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private var main: some View {
        Group {
            if vm.showsDiff {
                diffTagList(for: vm.diffResults)
            } else {
                columnsView
            }
        }.frame(minWidth: 800.0)
    }
    
    @ViewBuilder
    private var onlyDiffShortcut: some View {
        EmptyView().background {
            Button("only diff") {
                vm.showOnlyDifferent.toggle()
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
            .hidden()
        }
    }
    
    @ViewBuilder
    private var columnsView: some View {
        HStack(spacing: commonPadding) {
            ForEach(0..<vm.columns, id: \.self, content: column(for:))
        }
    }
    
    @ViewBuilder
    private func column(for idx: Int) -> some View {
        GroupBox {
            if vm.initialTags[idx].isEmpty {
                textInput(for: idx)
            } else {
                tagList(for: vm.initialTags[idx])
            }
        }.frame(minHeight: 500.0)
    }
    
    @ViewBuilder
    private func textInput(for idx: Int) -> some View {
        TextEditor(text: $vm.texts[idx])
            .font(.largeTitle.monospaced())
            .focused($focusedEditor, equals: idx)
            .onChange(of: vm.texts[idx]) { text in
                vm.parse(string: text)
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
            }.padding(.bottom, commonPadding)
        }
        .transition(.opacity)
    }
    
    @ViewBuilder
    private func diffTagRowView(for diffPair: DiffedTagPair) -> some View {
        Group {
            switch (diffPair.lhs, diffPair.rhs) {
            case (let lhs?, let rhs?):
                HStack(alignment: .top, spacing: commonPadding) {
                    TagRowView(diffedTag: lhs)
                    Divider()
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
            if diffPair.isEqual || vm.showOnlyDifferent {
                Color.clear
            } else {
                diffBackground
                    .clipShape(RoundedRectangle(cornerRadius: 5.0, style: .continuous))
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

}

#if DEBUG
struct DiffView_Previews: PreviewProvider {
    static var previews: some View {
        DiffView()
    }
}
#endif
