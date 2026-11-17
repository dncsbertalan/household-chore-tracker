//
//  CurrentUserWrapperView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 15..
//

import SwiftUI

struct CurrentUserWrapperView: View {
    @Environment(\.container) private var container
    @Environment(AppState.self) private var appState
    
    var body: some View {
        CurrentUserView(
            viewModel: CurrentUserViewModel(
                userRepository: container.currentUserRepository,
                authService: container.authService,
                appState: appState
            )
        )
    }
}

#Preview {
    CurrentUserWrapperView()
        .environment(AppState())
        .environment(\.container, DependencyContainer.mock())
}
