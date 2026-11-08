//
//  ProfileView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

import SwiftUI

struct ProfileTabView: View {
    @Environment(AppState.self) private var appState
    @State private var router = ProfileRouter()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            ProfileView()
                .navigationDestination(for: ProfileRoute.self) { route in
                    destination(for: route)
                }
        }
        .sheet(item: $router.sheet) { sheet in
            sheetDestination(for: sheet)
        }
        .environment(router)
    }
    
    @ViewBuilder
    private func destination(for route: ProfileRoute) -> some View {
        switch route {
        case .main:
            ProfileView()
        }
    }
    
    @ViewBuilder
    private func sheetDestination(for sheet: ProfileSheet) -> some View {
        NavigationStack {
            switch sheet {
            case .login:
                LoginView(authService: AuthenticationService.shared, appState: appState)
                
            case .register:
                LoginView(authService: AuthenticationService.shared, appState: appState)
            }
        }
    }
}

#Preview {
    ProfileTabView()
        .environment(AppState())
}
