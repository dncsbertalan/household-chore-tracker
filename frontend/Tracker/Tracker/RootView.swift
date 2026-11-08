//
//  RootView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.locale) private var locale


    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            Text("faza")
                .tabItem { Label("tab.name.household", systemImage: "house") }
                .tag(AppState.Tab.household)
            
            Text("faza")
                .tabItem { Label("tab.name.chores", systemImage: "checklist") }
                .tag(AppState.Tab.chores)
            
            ProfileTabView()
                .tabItem { Label("tab.name.profile", systemImage: "person") }
                .tag(AppState.Tab.profile)
        }
        // Recreate screen models so stored validation messages also use the new language.
        .id(locale)
    }
}

#Preview {
    RootView()
        .environment(AppState())
}
