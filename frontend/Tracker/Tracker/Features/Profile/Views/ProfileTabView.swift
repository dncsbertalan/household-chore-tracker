//
//  ProfileView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

import SwiftUI

struct ProfileTabView: View {
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
                LoginView()
                
            case .register:
                LoginView()
            }
        }
    }
}

#Preview {
    ProfileTabView()
        .environment(AppState())
}
