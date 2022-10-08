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
    
    @EnvironmentObject private var appVM: AppVM
    @StateObject private var vm: MainVM = .init()
    @State private var searchItem: NSSearchToolbarItem?
    @State private var searchInProgress: Bool = false
    
    internal var body: some View {
        HStack(spacing: 0.0) {
            mainView
        }
        .background(shortcutButtons)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(vm.errorTitle, isPresented: $vm.showsAlert, actions: {
            Button("I'll do better next time") {}
        }, message: {
            Text(vm.errorMessage)
        })
        .animation(.easeIn, value: vm.showsDetails)
        .environmentObject(vm)
        .background {
            HostingWindowFinder { window in
                guard let window = window else { return }
                self.appVM.addWindow(window, viewModel: vm)
                self.searchItem = window.toolbar
                    .flatMap { $0.visibleItems }
                    .flatMap { items in
                        items
                            .compactMap { $0 as? NSSearchToolbarItem }
                            .first
                    }
            }.opacity(0.0)
        }
        .searchable(text: $vm.searchText)
        .onAppear(perform: vm.setUp)
        .navigationTitle(vm.title)
        .toolbar { toolbarItems }
        .focusedSceneValue(\.selectedTags, $vm.selectedTags)
        .focusedSceneValue(\.tabName, $vm.title)
        .focusedSceneValue(\.mainVM, .constant(vm))
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
        }
    }
    
    @ViewBuilder
    internal var mainView: some View {
        if vm.showingTags {
            VStack(spacing: 0.0) {
                TagListView(
                    tags: $vm.currentTagVMs,
                    searchInProgress: $searchInProgress
                )
            }
            .frame(maxWidth: .infinity)
            details
                .frame(width: detailWidth)
        } else {
            HintView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    private var details: some View {
        if vm.showsDetails {
            GroupBox {
                if let detailTag = vm.detailTag {
                    TagDetailView(vm: .init(emvTag: detailTag))
                } else {
                    Text("Select a tag to view the details")
                        .foregroundColor(.secondary)
                        .font(.title2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(commonPadding)
            .transition(.move(edge: .trailing))
        }
    }
    
    private var shortcutButtons: some View {
        Group {
            Button("Search") {
                guard let searchItem = searchItem else {
                    return
                }
                
                if searchInProgress {
                    searchItem.endSearchInteraction()
                    searchInProgress = false
                } else {
                    searchItem.beginSearchInteraction()
                    searchInProgress = true
                }
            }.frame(width: 0.0, height: 0.0)
                .keyboardShortcut("f", modifiers: [.command])
            
            Button(
                "Deselect all",
                action: appVM.deselectAll
            )
            .frame(width: 0.0, height: 0.0)
            .keyboardShortcut(.cancelAction)
        }.hidden()
    }
    
}
    
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .frame(width: 1000, height: 600)
            .environmentObject(AppVM())
    }
}
