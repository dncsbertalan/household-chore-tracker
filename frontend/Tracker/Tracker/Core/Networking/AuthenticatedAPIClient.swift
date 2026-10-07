import Foundation

/// Opt-in authenticated transport. Public auth requests continue to use APIClient directly.
nonisolated struct AuthenticatedAPIClient: Sendable {
    private let client: APIClient
    private let session: TokenRefreshService

    init(client: APIClient, session: TokenRefreshService) {
        self.client = client
        self.session = session
    }

    func send<Response: Decodable & Sendable>(
        _ endpoint: APIEndpoint, as type: Response.Type = Response.self
    ) async throws -> Response {
        let token = try await session.accessToken()
        do {
            return try await client.send(authorizing(endpoint, token: token), as: type)
        } catch APIError.http(let status, _) where status == 401 {
            // Only safe reads are automatically replayed. Mutations require explicit feature policy.
            guard endpoint.method == .get else { throw SessionError.sessionExpired }
            let renewed = try await session.accessToken(rejectedToken: token)
            do {
                return try await client.send(authorizing(endpoint, token: renewed), as: type)
            } catch APIError.http(let status, _) where status == 401 {
                try await session.invalidate(accessToken: renewed)
                throw SessionError.sessionExpired
            }
        }
    }

    private func authorizing(_ endpoint: APIEndpoint, token: String) -> APIEndpoint {
        var request = endpoint
        request.headers["Authorization"] = "Bearer \(token)"
        return request
    }
}
