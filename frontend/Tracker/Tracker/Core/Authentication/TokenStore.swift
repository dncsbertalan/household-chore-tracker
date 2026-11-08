//
//  TokenStore.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import Foundation
import Security

actor TokenStore {
    static let shared = TokenStore()
    
    private let tokenKey = "auth.tokens"


    private(set) var accessToken: String?
    private(set) var refreshToken: String?
    private var isRefreshing = false
    private var refreshContinuations: [CheckedContinuation<String, Error>] = []

    func setTokens(_ tokens: TokenResponse) throws {
        self.accessToken = tokens.accessToken
        self.refreshToken = tokens.refreshToken
        // Persist to Keychain in production
        try KeychainManager.save(tokens, forKey: tokenKey)
    }

    func clearTokens() throws {
        accessToken = nil
        refreshToken = nil
        try KeychainManager.delete(forKey: tokenKey)
    }

    func loadFromKeychain() throws {
        var tokens = try KeychainManager.load(AuthTokens.self, forKey: tokenKey)
        accessToken = tokens?.accessToken
        refreshToken = tokens?.refreshToken
    }

    /// Refresh the access token. Coalesces multiple concurrent calls.
    func refreshAccessToken() async throws -> String {
        if isRefreshing {
            return try await withCheckedThrowingContinuation { continuation in
                refreshContinuations.append(continuation)
            }
        }

        isRefreshing = true

        do {
            guard let refreshToken else { throw APIError.unauthorized }

            // Call your auth endpoint to get a new access token
            var request = URLRequest(url: URL(string: "https://api.example.com/v1/auth/refresh")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["refresh_token": refreshToken])

            let (data, _) = try await URLSession.shared.data(for: request)
            let tokens = try JSONDecoder().decode(TokenResponse.self, from: data)

            try setTokens(tokens)
            isRefreshing = false

            // Resume all waiting callers
            for continuation in refreshContinuations {
                continuation.resume(returning: tokens.accessToken)
            }
            refreshContinuations.removeAll()

            return tokens.accessToken
        } catch {
            isRefreshing = false
            for continuation in refreshContinuations {
                continuation.resume(throwing: error)
            }
            refreshContinuations.removeAll()
            throw error
        }
    }
}
