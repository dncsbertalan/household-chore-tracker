//
//  WelcomeView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 15..
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.container) private var container
    @Environment(AppState.self) private var appState

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
                }
                
                Spacer()
                                
                VStack(spacing: Theme.Spacing.lg) {
                    Button {
                    } label: {
                        HStack(spacing: Theme.Spacing.md) {
                                Text("common.signUp")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.glassProminent)
                    
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("common.alreadyHasAccount.question")
                            .foregroundStyle(.secondary)
                        
                        NavigationLink {
                            LoginView(authService: container.authService,appState: appState)
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
}
