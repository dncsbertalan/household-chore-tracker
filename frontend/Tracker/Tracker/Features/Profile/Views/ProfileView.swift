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
            CurrentUserWrapperView()
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
        .environment(ProfileRouter())
}
