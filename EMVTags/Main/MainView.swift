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
    @StateObject private var windowVM: WindowVM = .init()
    @EnvironmentObject private var infoDataSource: EMVTagInfoDataSource
    
    @State private var showingAlert: Bool = false
    @State private var showingSearch = false
    @State private var showingTags = false
    @FocusState private var searchFocused
    
    internal var body: some View {
        HStack(spacing: 0.0) {
            mainView
        }
        .background(shortcutButtons)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Error!", isPresented: $showingAlert, actions: {
            Button("I'll do better next time") {
                self.showingAlert = false
            }
        }, message: {
            Text("Unable to parse given string into BERTLV")
        })
        .onChange(of: showingSearch) { _ in
            searchFocused = showingSearch
        }
        .environmentObject(windowVM)
        .background {
            HostingWindowFinder { window in
                guard let window = window else { return }
                self.appVM.addWindow(window, viewModel: windowVM)
            }.opacity(0.0)
        }
    }
    
    @ViewBuilder
    internal var mainView: some View {
        if showingTags {
            VStack(spacing: 0.0) {
                if showingSearch {
                    SearchBar(searchText: $windowVM.searchText, focused: _searchFocused)
                        .padding([.top, .leading], commonPadding)
                }
                TagListView()
                    .environmentObject(windowVM)
            }
            .frame(maxWidth: .infinity)
            details
                .frame(width: detailWidth)
        } else {
            HintView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var details: some View {
        GroupBox {
            if let selectedTag = windowVM.selectedTag {
                TagDetailView(vm: .init(emvTag: selectedTag))
            } else {
                Text("Select a tag to view the details")
                    .foregroundColor(.secondary)
                    .font(.title2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }.padding(commonPadding)
    }
    
    private var shortcutButtons: some View {
        Group {
            Button("Search") {
                showingSearch.toggle()
            }.frame(width: 0.0, height: 0.0)
                .keyboardShortcut("f", modifiers: [.command])
            Button("Paste") {
                guard let pasteString = NSPasteboard.general.string(forType: .string) else {
                    return
                }
                parse(string: pasteString)
            }.frame(width: 0.0, height: 0.0)
                .keyboardShortcut("v", modifiers: [.command])
        }.hidden()
    }
    
    private func parse(string: String) {
        do {
            let tlv = try InputParser.parse(input: string)
            
            windowVM.initialTags = tlv.map { EMVTag(tlv: $0, kernel: .general, infoSource: infoDataSource) }
            
            let pairs = windowVM.initialTags.flatMap { tag in
                [(tag.id, tag.searchString)] + tag.subtags.map { ($0.id, $0.searchString) }
            }
            
            windowVM.currentTags = windowVM.initialTags
            windowVM.tagDescriptions = .init(uniqueKeysWithValues: pairs)
            windowVM.selectedTag = nil
            showingTags = true
        } catch {
            showingAlert = true
        }
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

