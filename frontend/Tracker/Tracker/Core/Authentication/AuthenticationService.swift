//
//  AuthenticationService.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import Foundation

protocol AuthenticationServiceProtocol: Sendable {
    func login(email: String, password: String) async throws -> AuthTokens
    func logout() async throws
    func restoreSession() async throws -> AuthTokens?
}

struct AuthenticationService: AuthenticationServiceProtocol {
    private let api: APIClient
    private let tokenStore: any TokenStoreProtocol

    init(api: APIClient, tokenStore: any TokenStoreProtocol) {
        self.api = api
        self.tokenStore = tokenStore
    }

    func login(email: String, password: String) async throws -> AuthTokens {
        // 1. Authenticate against the backend
        let response = try await api.request(endpoint: "")(
            email: email,
            password: password
        )

        // 2. Convert the response into our model
        let tokens = response.toTokens()

        // 3. Persist the tokens securely
        try await tokenStore.save(tokens)

        // 4. Return the authenticated session
        return tokens
    }

    func logout() async throws {
        try await tokenStore.clear()
    }

    func restoreSession() async throws -> AuthTokens? {
        try await tokenStore.load()
    }
}
