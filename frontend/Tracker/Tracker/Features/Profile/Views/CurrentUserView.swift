//
//  CurrentUserView.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import SwiftUI

struct CurrentUserView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: CurrentUserViewModel
    
    init(viewModel: CurrentUserViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("profile.loading")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
            } else if let user = viewModel.user {
                profileHeader(for: user)
                
            }
            
            Spacer()
            
            Text("Authenticated: \(appState.isAuthenticated.description)")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(.green.opacity(0.15))
                )
            
            Text("Current user: \(appState.currentUserId)")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(.green.opacity(0.15))
                )
            
            Text("Current user error: \(appState.currentUserError?.localizedLowercase)")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(.green.opacity(0.15))
                )
            
            if appState.isAuthenticated {
                Button(role: .destructive, action: {
                    Task {
                        await viewModel.logout()
                    }
                }) {
                    HStack(spacing: 8) {
                        if viewModel.isLoggingOut {
                            ProgressView()
                        }
                        Text("profile.logOut")
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .foregroundStyle(.red)
                .buttonStyle(.bordered)
                .disabled(viewModel.isLoggingOut)
            }
        }
        .padding()
        .refreshable {
            await viewModel.load()
        }
        .task {
            await viewModel.load()
        }
    }
    
    private func profileHeader(for user: CurrentUser) -> some View {
        var name = PersonNameComponents()
        name.givenName = user.firstName
        name.familyName = user.lastName
        let displayName = PersonNameComponentsFormatter.localizedString(from: name, style: .medium)
        
        return VStack(spacing: 16) {
            AvatarView(firstName: user.firstName, lastName: user.lastName, size: 104)
            
            VStack {
                Text(displayName)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                Text(user.email)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

private let previewAppState: AppState = {
    let appState = AppState()
    appState.isAuthenticated = true
    return appState
}()

#Preview {
    CurrentUserWrapperView()
        .environment(previewAppState)
        .environment(\.container, DependencyContainer.mock())
}
