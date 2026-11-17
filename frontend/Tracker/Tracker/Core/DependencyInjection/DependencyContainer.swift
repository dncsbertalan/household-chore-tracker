//
//  DIContainer.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 15..
//

import Foundation

@MainActor
final class DependencyContainer {

    let apiClient: APIClient
    let householdRepository: any HouseholdRepositoryProtocol
    let currentUserRepository: any CurrentUserRepositoryProtocol
    let tokenStore: any TokenStoreProtocol
    let authService: any AuthenticationServiceProtocol

    init(
        tokenStore: (any TokenStoreProtocol)? = nil,
        apiClient: APIClient? = nil,
        authService: (any AuthenticationServiceProtocol)? = nil,
        currentUserRepository: (any CurrentUserRepositoryProtocol)? = nil,
        householdRepository: (any HouseholdRepositoryProtocol)? = nil
    ) {
        let resolvedTokenStore = tokenStore ?? KeychainTokenStore()
        let resolvedAPIClient = apiClient
            ?? APIClient(tokenStore: resolvedTokenStore)

        self.tokenStore = resolvedTokenStore
        self.apiClient = resolvedAPIClient

        self.authService = authService
            ?? AuthenticationService(
                apiClient: resolvedAPIClient,
                tokenStore: resolvedTokenStore
            )

        self.householdRepository = householdRepository
            ?? HouseholdRepository(apiClient: resolvedAPIClient)

        self.currentUserRepository = currentUserRepository
            ?? CurrentUserRepository(apiClient: resolvedAPIClient)
    }

    // MARK: - Mock

    static func mock() -> DependencyContainer {
        DependencyContainer(
            currentUserRepository: PreviewCurrentUserRepository(),
            householdRepository: PreviewHouseholdRepository()
        )
    }
}
