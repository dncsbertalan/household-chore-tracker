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
            CurrentUserWrapperView()
        } else {
            ContentUnavailableView {
                Label("auth.not_logged_in.label", systemImage: "person")
            } description: {
                Text("auth.not_logged_in.description")
            } actions: {
                Button("register") {
                    router.sheet = .register
                }
                .buttonSizing(.flexible)
                .buttonStyle(.bordered)
                
                Button("login") {
                    router.sheet = .login
                }
                .buttonSizing(.flexible)
                .frame(minWidth: 150)
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
        .environment(ProfileRouter())
}
