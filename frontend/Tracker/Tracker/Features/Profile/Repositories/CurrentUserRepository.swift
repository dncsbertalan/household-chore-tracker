//
//  CurrentUserRepositoryProtocol.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

nonisolated struct CurrentUserRepository: CurrentUserRepositoryProtocol {
    private let api: APIClient

    init(api: APIClient) { self.api = api }

    func getCurrentUser() async throws -> CurrentUser {
        try await api.request(endpoint: "api/v1/users/me")
    }
}
