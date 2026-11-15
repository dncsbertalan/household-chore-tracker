//
//  AuthenticationView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 15..
//

import SwiftUI

struct WelcomeMainView: View {
    @Environment(\.container) private var container
    @Environment(AppState.self) private var appState

    @State private var router = WelcomeRouter()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            WelcomeView()
                .navigationDestination(for: WelcomeRoute.self) { route in
                    destination(for: route)
                }
        }
        .sheet(item: $router.sheet) { sheet in
            sheetDestination(for: sheet)
        }
        .environment(router)
    }
    
    @ViewBuilder
    private func destination(for route: WelcomeRoute) -> some View {
        switch route {
        case .login:
            LoginView(authService: container.authService, appState: appState)
        case .register:
            RegisterView(authService: container.authService)
        }
    }
    
    @ViewBuilder
    private func sheetDestination(for sheet: WelcomeSheet) -> some View {
        NavigationStack {
            switch sheet {
            case .forgotPassword:
                LoginView(authService: container.authService, appState: appState)
            }
        }
    }
}

#Preview {
    let container = DependencyContainer()

    WelcomeMainView()
        .environment(\.container, container)
        .environment(AppState())
}
