//
//  MainView.swift
//  BERTLVEMV
//
//  Created by Yurii Zadoianchuk on 10/03/2022.
//

import SwiftUI
import Combine
import SwiftyEMVTags
import SwiftyBERTLV

struct MainView: View {
    
    @State private var showsKernelsPopover: Bool = false
    @State private var searchInProgress: Bool = false
    @SceneStorage("main-view.showsDetails") private var showsDetailsSceneStorage: Bool = true
    
    @ObservedObject internal var vm: MainVM
    
    internal var body: some View {
        mainView
        .background(shortcutButtons)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environmentObject(vm)
        .sheet(isPresented: $vm.presentingWhatsNew) {
            appVersion
                .map(WhatsNewVM.vm(for:))
                .map(WhatsNewView.init(vm:))
        }
        .searchable(text: $vm.searchText, isPresented: $searchInProgress)
        .navigationTitle(vm.title)
        .toolbar { toolbarItems }
        .focusedSceneValue(\.currentWindow, .main(vm))
        .inspector(isPresented: showsDetailsBinding) {
            details
                .inspectorColumnWidth(min: 320.0, ideal: detailWidth, max: 700.0)
        }
        .onAppear {
            if showsDetailsSceneStorage != vm.showsDetails {
                showsDetailsSceneStorage = vm.showsDetails
            }
        }
        .onChange(of: vm.showsDetails) { _, newValue in
            if showsDetailsSceneStorage != newValue {
                showsDetailsSceneStorage = newValue
            }
        }
        .onChange(of: showsDetailsSceneStorage) { _, newValue in
            if vm.showsDetails != newValue {
                vm.showsDetails = newValue
            }
        }
        .onChange(of: showsKernelsPopover) { oldValue, newValue in
            if oldValue == true, newValue == false {
                onMain {
                    // WWDC 2024
                    // Need to set search to inactive after the popover is hidden for some reason
                    self.searchInProgress = false
                }
            }
        }.errorAlert($vm.alert)
    }
    
    @ToolbarContentBuilder
    internal var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: vm.collapseAll) {
                Label("Collapse all", systemImage: "chevron.right.square")
            }.keyboardShortcut(.leftArrow, modifiers: [])
            
            Button(action: vm.expandAll) {
                Label("Expand all", systemImage: "chevron.down.square")
            }.keyboardShortcut(.rightArrow, modifiers: [])
            
            Button(action: vm.toggleShowsDetails) {
                Label("Details", systemImage: "sidebar.right")
            }
            
            Button(action: {
                showsKernelsPopover.toggle()
            }) {
                Label("Kernels", systemImage: KernelInfo.iconName)
            }
            .keyboardShortcut("k", modifiers: [.command, .shift])
            .popover(
                isPresented: $showsKernelsPopover,
                content: kernelSelectionList
            )
        }
    }
    
    @ViewBuilder
    internal var mainView: some View {
        if vm.showsTags {
            ScrollView {
                TagListView(
                    tags: {
                        let editedIds = Set(vm.editedTags.keys)
                        return vm.currentTags.map { .init(tag: $0, isSubtag: false, editedIds: editedIds) }
                    }(),
                    searchInProgress: $searchInProgress
                )
            }
            .frame(maxWidth: .infinity)
        } else {
            HintView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    private var details: some View {
        GroupBox {
            if let detailTag = vm.detailTag {
                ScrollView {
                    detailViews(vms: detailTag.tagDetailsVMs)
                }
            } else {
                tagSelectionHint
                    .padding(commonPadding)
            }
        }
        .transition(.move(edge: .trailing))
        .padding(commonPadding)
    }

    private var showsDetailsBinding: Binding<Bool> {
        .init(
            get: { showsDetailsSceneStorage },
            set: { newValue in
                showsDetailsSceneStorage = newValue
                vm.showsDetails = newValue
            }
        )
    }
    
    @ViewBuilder
    private func detailViews(vms: [TagDetailsVM]) -> some View {
        if let first = vms.first, vms.count == 1 {
            TagDetailsView(vm: first)
                .padding(-commonPadding)
                .environment(\.bitToggleHandler, vm.toggleBit)
        } else {
            TabView {
                ForEach(vms, id: \.kernel) { detailVM in
                    TagDetailsView(vm: detailVM)
                        .tabItem {
                            Text(detailVM.kernel)
                                .frame(maxWidth: .infinity)
                        }
                }
            }
            .environment(\.bitToggleHandler, vm.toggleBit)
        }
    }
    
    private var tagSelectionHint: some View {
        Text("Select a tag to view the details")
            .foregroundStyle(.secondary)
            .font(.title2)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var shortcutButtons: some View {
        Group {
            Button("Search") {
                searchInProgress.toggle()
            }
            .frame(width: 0.0, height: 0.0)
            .keyboardShortcut("f", modifiers: [.command])
            
            Button(
                "Deselect",
                action: vm.deselectAll
            ).keyboardShortcut(.cancelAction)
            
            Button(
                "Clear Window",
                action: vm.clearWindow
            ).keyboardShortcut(.escape, modifiers: [.command])
        }.hidden()
    }
    
    private func kernelSelectionList() -> some View {
        KernelSelectionListView(
            vm: .init(tagParser: vm.tagParser)
        ).frame(minWidth: 250.0)
    }
    
}
    
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(vm: MainVM())
            .frame(width: 1000, height: 600)
            .environmentObject(AppVM.shared)
    }
}
