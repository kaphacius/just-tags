//
//  JustTagsApp.swift
//  JustTags
//
//  Created by Yurii Zadoianchuk on 20/03/2022.
//

import SwiftUI
import SwiftyEMVTags

@main
internal struct JustTagsApp: App {
    
    @StateObject private var appVM = AppVM()
    
    internal var body: some Scene {
        WindowGroup {
            MainView()
                .blur(radius: appVM.setUpInProgress ? 30.0 : 0.0)
                .overlay {
                    if appVM.setUpInProgress {
                        ProgressView().progressViewStyle(.circular)
                    }
                }
                .environmentObject(appVM)
                .handlesExternalEvents(preferring: ["main"], allowing: ["main"])
        }
        .commands {
            MainViewCommands(vm: appVM)
        }
        .handlesExternalEvents(matching: ["main"])
        
        
        WindowGroup("Diff") {
            DiffView()
                .environmentObject(appVM)
                .handlesExternalEvents(preferring: ["diff"], allowing: ["diff"])
        }.handlesExternalEvents(matching: ["diff"])
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
