//
//  CurrentUserRepositoryProtocol.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

nonisolated struct CurrentUserRepository: CurrentUserRepositoryProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient) { self.apiClient = apiClient }

    func getCurrentUser() async throws -> CurrentUser {
        try await apiClient.request(endpoint: "api/v1/users/me")
    }
}
