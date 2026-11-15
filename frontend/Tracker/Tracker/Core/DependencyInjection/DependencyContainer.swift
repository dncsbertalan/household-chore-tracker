//
//  DIContainer.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 15..
//

import Foundation

@MainActor
final class DependencyContainer: Sendable {
    let apiClient: APIClient
    let currentUserRepository: CurrentUserRepositoryProtocol
    let tokenStore: TokenStoreProtocol
    let authService: AuthenticationServiceProtocol

    init() {
        self.tokenStore = KeychainTokenStore()
        self.apiClient = APIClient(tokenStore: tokenStore)
        self.authService = AuthenticationService(apiClient: apiClient, tokenStore: tokenStore)
        self.currentUserRepository = CurrentUserRepository(apiClient: apiClient)
    }

    /// Creates a container with mock implementations for previews and tests
    static func mock() -> DependencyContainer? {
        nil
    }
}
