//
//  TrackerApp.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

import SwiftUI
import SwiftData

@main
struct TrackerApp: App {
    @AppStorage(AppLanguage.storageKey)
    private var language = AppLanguage.system.rawValue
    
    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: language) ?? .system
    }
    
    @State var appState: AppState = AppState()
    
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
        .environment( \.locale, selectedLanguage.locale)
        .environment(appState)
    }
}
