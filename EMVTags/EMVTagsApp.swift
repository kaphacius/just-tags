//
//  EMVTagsApp.swift
//  EMVTags
//
//  Created by Yurii Zadoianchuk on 20/03/2022.
//

import SwiftUI
import SwiftyEMVTags

@main
internal struct EMVTagsApp: App {
    
    @StateObject private var infoDataSource: EMVTagInfoDataSource
    @StateObject private var appVM = AppVM()
    
    internal var body: some Scene {
        WindowGroup {
                MainView()
                .environmentObject(infoDataSource)
                .environmentObject(appVM)
                .handlesExternalEvents(preferring: ["main"], allowing: ["main"])
        }
        .commands {
            MainViewCommands(viewModel: appVM)
        }
        .handlesExternalEvents(matching: ["main"])
        
        
        WindowGroup("Diff") {
            DiffView()
                .environmentObject(infoDataSource)
                .handlesExternalEvents(preferring: ["diff"], allowing: ["diff"])
        }.handlesExternalEvents(matching: ["diff"])
    }
    
    internal init() {
        let commonTags: Array<EMVTag.Info>
        
        if let url = Bundle.main.path(forResource: "common_tags", ofType: "json"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: url)),
           let decoded = try? JSONDecoder().decode(TagInfoContainer.self, from: data) {
            commonTags = decoded.tags
        } else {
            commonTags = []
        }
        
        self._infoDataSource = .init(wrappedValue: .init(infoList: commonTags))
    }
}

final class EMVTagInfoDataSource: AnyEMVTagInfoSource, ObservableObject {
    
    @Published internal var infoList: Array<EMVTag.Info> = []
    
    internal init(infoList: [EMVTag.Info]) {
        self.infoList = infoList
    }
    
    func info(for tag: UInt64, kernel: EMVTag.Kernel) -> EMVTag.Info {
        infoList.first(
            where: { $0.tag == tag &&
                $0.kernel.matches(kernel)
            }
        ) ?? .unknown(tag: tag)
    }
    
}
