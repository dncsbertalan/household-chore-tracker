import Foundation

actor TokenRefresher {
    private let baseURL: URL
    private let session: URLSession
    private let tokenStore: any TokenStoreProtocol
    private var pending: (id: UUID, task: Task<String?, Error>)?

    init(baseURL: URL, session: URLSession, tokenStore: any TokenStoreProtocol) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStore = tokenStore
    }

    func accessToken(rejected: String? = nil) async throws -> String? {
        if let pending {
            let token = try await pending.task.value
            if let rejected, token == rejected {
                // The joined operation may have only read a still-valid token.
                if self.pending?.id == pending.id { self.pending = nil }
                return try await accessToken(rejected: rejected)
            }
            return token
        }
        return try await start(rejected: rejected)
    }

    private func start(rejected: String?) async throws -> String? {
        let task = Task { try await self.resolve(rejected: rejected) }
        let id = UUID()
        pending = (id, task)
        defer { if pending?.id == id { pending = nil } }
        return try await task.value
    }

    private func resolve(rejected: String?) async throws -> String? {
        guard let tokens = try await tokenStore.load() else { return nil }
        guard tokens.refreshPending != true else { throw APIError.unauthorized }
        if tokens.accessExpiresAt > Date(), tokens.accessToken != rejected { return tokens.accessToken }
        guard tokens.refreshExpiresAt > Date() else { throw APIError.unauthorized }

        // Fetch CSRF before marking rotation pending: failure here cannot consume the refresh token.
        let csrf: RefreshCSRFResponse = try await request(endpoint: "api/v1/auth/csrf")
        guard try await tokenStore.load() == tokens else { throw APIError.unauthorized }
        var rotating = tokens
        rotating.refreshPending = true
        try await tokenStore.save(rotating)
        let issuedAt = Date()
        let response: TokenResponse = try await request(endpoint: "api/v1/auth/refresh",
            body: RefreshTokenRequest(refreshToken: tokens.refreshToken), headers: [csrf.headerName: csrf.token])
        let replacement = try StoredTokens(response: response, issuedAt: issuedAt)
        // Do not restore a session that was logged out or replaced while refresh was in flight.
        guard try await tokenStore.load() == rotating else { throw APIError.unauthorized }
        try await tokenStore.save(replacement)
        return replacement.accessToken
    }

    private func request<T: Decodable>(endpoint: String, body: RefreshTokenRequest? = nil,
                                       headers: [String: String] = [:]) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint))
        request.httpMethod = body == nil ? "GET" : "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(response.statusCode) else {
            throw APIError.from(statusCode: response.statusCode, data: data)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

nonisolated private struct RefreshCSRFResponse: Decodable {
    let headerName: String
    let token: String
}

nonisolated private struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}
