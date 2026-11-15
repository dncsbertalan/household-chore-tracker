//
//  WelcomeView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 15..
//

import SwiftUI

private enum AuthRoute: Hashable {
    case login
    case register
}

struct WelcomeView: View {
    @Environment(\.container) private var container
    @Environment(AppState.self) private var appState
    @Environment(WelcomeRouter.self) private var router
    
    @State private var path: [AuthRoute] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.huge) {
                Spacer()

                Image(systemName: "house")
                    .font(.system(size: 66, weight: .medium))
                    .foregroundStyle(.tint)
                    .frame(width: 120, height: 120)
                    .background(
                        Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: Theme.CornerRadius.xxxl)
                    )
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    Text("welcome.welcome")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    
                    Text("welcome.label")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                                
                VStack(spacing: Theme.Spacing.lg) {                    
                    Button {
                        router.navigate(to: .register)
                    } label: {
                        Text("common.signUp")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.glassProminent)

                    HStack(spacing: Theme.Spacing.xs) {
                        Text("common.alreadyHasAccount.question")
                            .foregroundStyle(.secondary)
                        
                        Button {
                            router.navigate(to: .login)
                        } label: {
                            Text("common.alreadyHasAccount.signIn")
                        }
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
    }
}

#Preview {
    let container = DependencyContainer()
    
    WelcomeView()
        .environment(\.container, container)
        .environment(AppState())
        .environment(WelcomeRouter())
}
