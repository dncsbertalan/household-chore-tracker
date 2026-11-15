//
//  AuthenticationService.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import Foundation

protocol AuthenticationServiceProtocol: Sendable {
    func login(email: String, password: String) async throws -> StoredTokens
    func register(email: String, password: String, firstName: String, lastName: String) async throws -> RegistrationResponse
    func logout() async throws
    func restoreSession() async throws -> StoredTokens?
}

struct AuthenticationService: AuthenticationServiceProtocol {
    private let apiClient: APIClient
    private let tokenStore: any TokenStoreProtocol

    init(apiClient: APIClient, tokenStore: any TokenStoreProtocol) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
    }

    /// Authenticates and persists the session before returning it.
    func login(email: String, password: String) async throws -> StoredTokens {
        let csrf = try await csrfToken()
        let issuedAt = Date()
        
        let response: TokenResponse = try await apiClient.request(
            endpoint: "api/v1/auth/login", method: .post,
            body: LoginRequest(email: email, password: password),
            headers: [csrf.headerName: csrf.token]
        )
        
        let tokens = try StoredTokens(response: response, issuedAt: issuedAt)
        
        try await tokenStore.save(tokens)
        
        return tokens
    }

    /// Creates an account. Call login separately to start an authenticated session.
    func register(email: String, password: String, firstName: String, lastName: String) async throws -> RegistrationResponse {
        let csrf = try await csrfToken()
        return try await apiClient.request(
            endpoint: "api/v1/auth/register", method: .post,
            body: RegisterRequest(email: email, password: password, firstName: firstName, lastName: lastName),
            headers: [csrf.headerName: csrf.token]
        )
    }

    // Spring requires a CSRF header plus the session cookie from this GET.
    // Both requests use the API client's same cookie-enabled URLSession.
    private func csrfToken() async throws -> CSRFResponse {
        try await apiClient.request(endpoint: "api/v1/auth/csrf")
    }

    /// Clears local credentials; the backend currently has no logout endpoint.
    func logout() async throws {
        try await tokenStore.clear()
    }

    func restoreSession() async throws -> StoredTokens? {
        guard let tokens = try await tokenStore.load(), tokens.refreshPending != true else {
            return nil
        }
        
        let now = Date()
        
        guard tokens.accessExpiresAt > now || tokens.refreshExpiresAt > now else {
            return nil
        }
        
        return tokens
    }
}

nonisolated private struct LoginRequest: Encodable {
    let email: String
    let password: String
}

nonisolated private struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
}

nonisolated private struct CSRFResponse: Decodable {
    let headerName: String
    let token: String
}

nonisolated struct RegistrationResponse: Decodable, Sendable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
}
