import Foundation

/// Opt-in authenticated transport. Public auth requests continue to use APIClient directly.
nonisolated struct AuthenticatedAPIClient: APIClientProtocol {
    private let client: any APIClientProtocol
    private let session: TokenRefreshService

    init(client: any APIClientProtocol, session: TokenRefreshService) {
        self.client = client
        self.session = session
    }

    func send<Response: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        as type: Response.Type = Response.self
    ) async throws -> Response {
        try await perform(endpoint) { endpoint in
            try await client.send(endpoint, as: type)
        }
    }

    func sendWithoutResponse(_ endpoint: APIEndpoint) async throws {
        try await perform(endpoint) { endpoint in
            try await client.sendWithoutResponse(endpoint)
        }
    }

    private func perform<Response: Sendable>(
        _ endpoint: APIEndpoint,
        operation: @Sendable (APIEndpoint) async throws -> Response
    ) async throws -> Response {
        let token = try await session.accessToken()
        do {
            let request = try await verifiedRequest(endpoint, token: token)
            return try await operation(request)
        } catch APIError.http(let status, _) where status == 401 {
            // Only safe reads are automatically replayed. Mutations require explicit feature policy.
            guard endpoint.method == .get else {
                throw SessionError.sessionExpired
            }
            let renewed = try await session.accessToken(rejectedToken: token)
            do {
                let request = try await verifiedRequest(endpoint, token: renewed)
                return try await operation(request)
            } catch APIError.http(let status, _) where status == 401 {
                try await session.invalidate(accessToken: renewed)
                throw SessionError.sessionExpired
            }
        }
    }

    private func verifiedRequest(_ endpoint: APIEndpoint, token: String) async throws -> APIEndpoint {
        if let expectedAccountId = endpoint.expectedAccountId {
            let user = try await client.send(
                authorizing(APIEndpoint(path: "users/me"), token: token), as: CurrentUser.self
            )
            guard user.id == expectedAccountId else { throw SessionError.signInRequired }
        }
        try Task.checkCancellation()
        return authorizing(endpoint, token: token)
    }

    private func authorizing(_ endpoint: APIEndpoint, token: String)
        -> APIEndpoint
    {
        var request = endpoint
        request.headers["Authorization"] = "Bearer \(token)"
        return request
    }
}
