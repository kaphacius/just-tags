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
    
    @ObservedObject internal var vm: MainVM
    
    internal var body: some View {
        HStack(spacing: 0.0) {
            mainView
        }
        .background(shortcutButtons)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeIn, value: vm.showsDetails)
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
                    tags: vm.currentTags.map { .init(tag: $0, isSubtag: false) },
                    searchInProgress: $searchInProgress
                )
            }
            .frame(maxWidth: .infinity)
            if vm.showsDetails {
                details
                    .frame(width: detailWidth)
            }
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
    
    @ViewBuilder
    private func detailViews(vms: [TagDetailsVM]) -> some View {
        if let first = vms.first, vms.count == 1 {
            TagDetailsView(vm: first)
                .padding(-commonPadding)
        } else {
            TabView {
                ForEach(vms, id: \.kernel) { vm in
                    TagDetailsView(vm: vm)
                        .tabItem {
                            Text(vm.kernel)
                                .frame(maxWidth: .infinity)
                        }
                }
            }
        }
    }
    
    private var tagSelectionHint: some View {
        Text("Select a tag to view the details")
            .foregroundColor(.secondary)
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
