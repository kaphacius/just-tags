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
    
    @StateObject var dataSource = TagsDataSource(tags: [])
    @State var tagDescriptions: Dictionary<UUID, String> = [:]
    @EnvironmentObject private var infoDataSource: EMVTagInfoDataSource
    
    @State private var initialTags: [EMVTag] = []
    @State private var selectedTag: EMVTag? = nil
    @State private var showingAlert: Bool = false
    @State private var searchText: String = ""
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showingSearch = false
    @FocusState private var searchFocused
    
    private var searchTextPublisher = CurrentValueSubject<String, Never>("")
    
    var body: some View {
        HStack(spacing: 0.0) {
            VStack(spacing: 0.0) {
                if showingSearch {
                    SearchBar(searchText: $searchText, focused: _searchFocused)
                        .padding([.top, .leading], commonPadding)
                }
                list
            }.background(shortcutButtons)
            .frame(maxWidth: .infinity)
            details
                .frame(width: detailWidth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            setUpSearch()
        }
        .onChange(of: searchText, perform: searchTextPublisher.send)
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
        .environmentObject(dataSource)
    }
    
    private var list: some View {
        TagListView(onTagSelected: { tag in
            self.selectedTag = tag
        })
    }
    
    private var details: some View {
        GroupBox {
            if let selectedTag = selectedTag {
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
        var parsedData: Data? = nil
        
        let hexStringBytes = string
            .replacingOccurrences(of: " ", with: "")
            .split(by: 2)
            .map { UInt8($0, radix: 16) }
        
        let compactedHexStringBytes = hexStringBytes.compactMap { $0 }
        
        if hexStringBytes.count == compactedHexStringBytes.count {
            parsedData = Data(compactedHexStringBytes)
        } else if let base64Bytes = Data(
            base64Encoded: string, options: .ignoreUnknownCharacters
        ) {
            parsedData = Data(base64Bytes)
        }
    
        guard let parsedData = parsedData,
              let tlv = try? BERTLV.parse(bytes: [UInt8](parsedData)) else {
                showingAlert = true
                return
            }
        
        initialTags = tlv.map { EMVTag(tlv: $0, kernel: .general, infoSource: infoDataSource) }
    
        let pairs = initialTags.flatMap { tag in
            [(tag.id, tag.searchString)] + tag.subtags.map { ($0.id, $0.searchString) }
        }
        
        tagDescriptions = .init(uniqueKeysWithValues: pairs)
        searchText = ""
        updateTags()
        selectedTag = nil
    }
    
    private func setUpSearch() {
        searchTextPublisher
            .debounce(for: 0.2, scheduler: RunLoop.main, options: nil)
            .removeDuplicates()
            .sink { _ in
                updateTags()
            }.store(in: &cancellables)
    }
    
    private func updateTags() {
        if searchText.count < 2 {
            dataSource.tags = initialTags
        } else {
            let matchingTags = Set(
                tagDescriptions
                .filter { $0.value.contains(searchText) }
                .keys
            )
            dataSource.tags = initialTags
                .filter { matchingTags.contains($0.id) }
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
        ].joined()
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

