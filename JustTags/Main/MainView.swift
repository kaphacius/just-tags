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
    @StateObject private var vm: MainWindowVM = .init()
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
        .environmentObject(vm as AnyWindowVM)
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
    }
    
    @ViewBuilder
    internal var mainView: some View {
        if vm.showingTags {
            VStack(spacing: 0.0) {
                header
                TagListView(
                    tags: $vm.currentTags,
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
    private var header: some View {
        GroupBox {
            HStack {
                Button("Expand all", action: vm.expandAll)
                Button("Collapse all", action: vm.collapseAll)
                Spacer()
                Button(action: vm.toggleShowsDetails) {
                    Image(systemName: "sidebar.right")
                }
            }
        }.padding([.top, .leading], commonPadding)
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

extension EMVTag {
    
    var searchString: String {
        [
            tag.hexString,
            name,
            description,
            subtags.map(\.searchString).joined(),
            decodedMeaningList
                .flatMap(\.bitList)
                .map(\.meaning)
                .filter { $0 != "RFU" }.joined()
        ].joined().lowercased()
    }
    
    func filtered(with string: String, matchingTags: Set<UUID>) -> EMVTag {
        if isConstructed {
            return .init(
                id: self.id,
                tag: self.tag,
                name: self.name,
                description: self.description,
                source: self.source,
                format: self.format,
                kernel: self.kernel,
                isConstructed: self.isConstructed,
                value: self.value,
                lengthBytes: self.lengthBytes,
                subtags: self.subtags.filter { matchingTags.contains($0.id) },
                decodedMeaningList: self.decodedMeaningList
            )
        } else {
            return self
        }
    }
    
}
    
//#if DEBUG
//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainView()
//            .frame(width: 600, height: 600)
//    }
//}
//#endif
//
//let pp = BERTLV.parse(bytes: [UInt8](data)).map(EMVTag.emvTag(with:))
//let ppp = BERTLV.parse(
//    bytes: [0x9F, 0x33, 0x03, 0x60, 0x28, 0xC8, 0x9F, 0x33, 0x03, 0x60, 0xC8, 0xC8, 0x9F, 0x34, 0x01, 0xFF])
//    .map(EMVTag.emvTag(with:))

