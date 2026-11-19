//
//  DIContainer.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 15..
//

import Foundation

@MainActor
final class DependencyContainer {

    let choreRepository: any ChoreRepositoryProtocol
    let apiClient: APIClient
    let householdRepository: any HouseholdRepositoryProtocol
    let householdInvitationRepository: any HouseholdInvitationRepositoryProtocol
    let currentUserRepository: any CurrentUserRepositoryProtocol
    let tokenStore: any TokenStoreProtocol
    let authService: any AuthenticationServiceProtocol

    init(
        choreRepository: (any ChoreRepositoryProtocol)? = nil,
        tokenStore: (any TokenStoreProtocol)? = nil,
        apiClient: APIClient? = nil,
        authService: (any AuthenticationServiceProtocol)? = nil,
        currentUserRepository: (any CurrentUserRepositoryProtocol)? = nil,
        householdRepository: (any HouseholdRepositoryProtocol)? = nil,
        householdInvitationRepository: (any HouseholdInvitationRepositoryProtocol)? = nil
    ) {
        let resolvedTokenStore = tokenStore ?? KeychainTokenStore()
        let resolvedAPIClient = apiClient
            ?? APIClient(tokenStore: resolvedTokenStore)

        self.choreRepository = choreRepository ?? ChoreRepository(apiClient: resolvedAPIClient)
        self.tokenStore = resolvedTokenStore
        self.apiClient = resolvedAPIClient

        self.authService = authService
            ?? AuthenticationService(
                apiClient: resolvedAPIClient,
                tokenStore: resolvedTokenStore
            )

        self.householdRepository = householdRepository
            ?? HouseholdRepository(apiClient: resolvedAPIClient)
        
        self.householdInvitationRepository = householdInvitationRepository
            ?? HouseholdInvitationRepository(apiClient: resolvedAPIClient)

        self.currentUserRepository = currentUserRepository
            ?? CurrentUserRepository(apiClient: resolvedAPIClient)
    }

    // MARK: - Mock

    static func mock() -> DependencyContainer {
        DependencyContainer(
            choreRepository: PreviewChoreRepository(),
            currentUserRepository: PreviewCurrentUserRepository(),
            householdRepository: PreviewHouseholdRepository(),
            householdInvitationRepository: PreviewHouseholdInvitationRepository()
        )
    }
}
