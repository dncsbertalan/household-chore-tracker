import Foundation

nonisolated enum SessionError: Error, LocalizedError, Sendable {
    case signInRequired
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .signInRequired: return String(localized: "auth.error.signInRequired")
        case .sessionExpired: return String(localized: "auth.error.sessionExpired")
        }
    }
}

nonisolated struct RefreshRequest: Encodable, Sendable {
    let refreshToken: String
}

/// Inject one instance into authenticated services; there is no global singleton.
actor TokenRefreshService {
    private let client: APIClient
    private let tokenStore: any TokenStoring
    private let now: @Sendable () -> Date
    private var inFlight: (id: UUID, refreshToken: String, task: Task<StoredTokens, Error>)?

    init(client: APIClient, tokenStore: any TokenStoring, now: @escaping @Sendable () -> Date = { Date() }) {
        self.client = client
        self.tokenStore = tokenStore
        self.now = now
    }

    func accessToken(rejectedToken: String? = nil) async throws -> String {
        try Task.checkCancellation()
        guard let tokens = try await tokenStore.load() else { throw SessionError.signInRequired }
        if let flight = inFlight, flight.refreshToken == tokens.refreshToken {
            let renewed = try await flight.task.value
            try Task.checkCancellation()
            return renewed.accessToken
        }
        // An old 401 must not trigger another refresh after a different request already rotated.
        let mustRefresh = rejectedToken == tokens.accessToken
        if !mustRefresh && tokens.refreshPending != true && tokens.accessExpiresAt > now() {
            return tokens.accessToken
        }
        guard tokens.refreshPending != true, tokens.refreshExpiresAt > now() else {
            _ = try await tokenStore.clear(ifMatching: tokens)
            throw SessionError.sessionExpired
        }
        let id = UUID()
        // This unstructured task intentionally survives cancellation of an individual UI waiter.
        // Once the server consumes a token, completing storage is required for all other callers.
        let task = Task { try await self.performRefresh(tokens) }
        inFlight = (id, tokens.refreshToken, task)
        defer { if inFlight?.id == id { inFlight = nil } }
        let renewed = try await task.value
        try Task.checkCancellation()
        return renewed.accessToken
    }

    func invalidate(accessToken: String) async throws {
        guard let tokens = try await tokenStore.load(), tokens.accessToken == accessToken else { return }
        _ = try await tokenStore.clear(ifMatching: tokens)
    }

    private func performRefresh(_ original: StoredTokens) async throws -> StoredTokens {
        // A failed CSRF GET is safe to try again later: the refresh POST has not been sent.
        let headers = try await CSRFService(client: client).headers()
        let endpoint = try APIEndpoint.json(
            "auth/refresh", body: RefreshRequest(refreshToken: original.refreshToken), headers: headers
        )
        var pending = original
        pending.refreshPending = true
        guard try await tokenStore.replace(pending, ifMatching: original) else {
            return try await currentTokensAfterSessionChange()
        }
        do {
            let issuedAt = now()
            let response = try await client.send(endpoint, as: TokenResponse.self)
            let rotated = try StoredTokens(response: response, issuedAt: issuedAt)
            guard rotated.refreshToken != original.refreshToken else { throw APIError.invalidResponse }
            guard try await tokenStore.replace(rotated, ifMatching: pending) else {
                return try await currentTokensAfterSessionChange()
            }
            return rotated
        } catch {
            // Never retry a refresh POST, including when a response was lost or storage failed.
            // If deletion fails, the persistent pending marker still prevents reuse next launch.
            if try await tokenStore.clear(ifMatching: pending) {
                throw SessionError.sessionExpired
            }
            return try await currentTokensAfterSessionChange()
        }
    }

    private func currentTokensAfterSessionChange() async throws -> StoredTokens {
        guard let current = try await tokenStore.load(), current.refreshPending != true,
              current.accessExpiresAt > now() else { throw SessionError.sessionExpired }
        return current
    }
}
