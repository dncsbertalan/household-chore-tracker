//
//  ProfileView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(ProfileRouter.self) private var router

    var body: some View {

        if appState.isAuthenticated {
            Text("Hello, World!")
        } else {
            ContentUnavailableView {
                Label("auth.not_logged_in.label", systemImage: "person")
            } description: {
                Text("auth.not_logged_in.description")
            } actions: {
                Button("register") {
                    router.sheet = .register
                }
                Button("login") {
                    router.sheet = .login
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
        .environment(ProfileRouter())
}
