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
    
    init(
        userRepository: any CurrentUserRepositoryProtocol = CurrentUserRepository(api: APIClient.shared), appState: AppState
    ) {
        _viewModel = State(
            initialValue: CurrentUserViewModel(userRepository: userRepository, authService: AuthenticationService.shared, appState: appState)
        )
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

private struct PreviewCurrentUserRepository: CurrentUserRepositoryProtocol {
    func getCurrentUser() async throws -> CurrentUser {
        CurrentUser(
            id: UUID(),
            email: "alex.morgan@example.com",
            firstName: "Alex",
            lastName: "Morgan"
        )
    }
}

private let previewAppState: AppState = {
    let appState = AppState()
    appState.isAuthenticated = true
    return appState
}()

#Preview {
    CurrentUserView(
        userRepository: PreviewCurrentUserRepository(),
        appState: previewAppState
    )
    .environment(previewAppState)
}
