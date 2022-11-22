//
//  DiffView.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 21/04/2022.
//

import SwiftUI
import SwiftyEMVTags

struct DiffView: View {
    
    @StateObject private var vm: DiffVM = .init()
    @EnvironmentObject private var appVM: AppVM
    @FocusState internal var focusedEditor: Int?
    
    // For preview purposes
    fileprivate init(vm: DiffVM) {
        self._vm = .init(wrappedValue: vm)
    }
    
    internal init() {}
    
    internal var body: some View {
        VStack(spacing: commonPadding) {
            header
            main
        }
        .onChange(of: focusedEditor, perform: vm.updateFocusedEditor)
        .animation(.none, value: vm.showOnlyDifferent)
        .padding(.horizontal, commonPadding)
        .padding(.top, commonPadding)
        .background {
            HostingWindowFinder { window in
                guard let window = window else { return }
                self.appVM.addWindow(window, viewModel: vm)
            }.opacity(0.0)
        }
        .environmentObject(vm as AnyWindowVM)
        .onAppear(perform: vm.setUp)
        .navigationTitle(vm.title)
        .errorAlert($vm.alert)
    }
    
    @ViewBuilder
    private var header: some View {
        GroupBox {
            HStack {
                Toggle("Show only different tags", isOn: $vm.showOnlyDifferent)
                    .background(onlyDiffShortcut)
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .trailing) {
                HStack {
                    Button(action: {
                        vm.flipSides()
                    }, label: {
                        Label("Flip sides", systemImage: "arrow.left.arrow.right.square.fill")
                            .labelStyle(.iconOnly)
                    }).keyboardShortcut("f", modifiers: [.command, .shift])
                    
                    Button(action: {
                        vm.showsKernelsPopover = true
                    }) {
                        Label("Kernels", systemImage: KernelInfo.iconName)
                            .labelStyle(.iconOnly)
                    }
                    .keyboardShortcut("k", modifiers: [.command, .shift])
                    .popover(
                        isPresented: $vm.showsKernelsPopover,
                        content: kernelSelectionList
                    )
                }
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
                ForEach(tags) { tag in
                    DiffedTagRowView(vm: tag.diffedTagRowVM)
                }
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
    
    private func kernelSelectionList() -> some View {
        KernelSelectionListView(
            vm: .init(tagParser: vm.tagParser)
        ).frame(minWidth: 250.0)
    }
    
    @ViewBuilder
    private func diffTagRowView(for diffPair: DiffedTagPair) -> some View {
        Group {
            switch (diffPair.lhs, diffPair.rhs) {
            case (let lhs?, let rhs?):
                HStack(alignment: .top, spacing: commonPadding) {
                    DiffedTagRowView(vm: lhs.diffedTagRowVM)
                    Divider()
                    DiffedTagRowView(vm: rhs.diffedTagRowVM)
                }
            case (let lhs?, _):
                HStack(spacing: commonPadding) {
                    DiffedTagRowView(vm: lhs.diffedTagRowVM)
                    Rectangle().hidden()
                }
            case (_, let rhs?):
                HStack(spacing: commonPadding) {
                    Rectangle().hidden()
                    DiffedTagRowView(vm: rhs.diffedTagRowVM)
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

struct DiffView_Previews: PreviewProvider {
    private static let viewModel = DiffVM(
        columns: 2,
        texts: [],
        initialTags: [EMVTag.mockDiffPair.0, EMVTag.mockDiffPair.1],
        diffResults: [],
        showOnlyDifferent: false
    )

    static var previews: some View {
        DiffView(vm: viewModel)
            .environmentObject(AppVM())
    }
}
