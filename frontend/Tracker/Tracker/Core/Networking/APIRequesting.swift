import Foundation

/// Shared interface for public and authenticated clients, and feature-service test doubles.
nonisolated protocol APIRequesting: Sendable {
    func send<Response: Decodable & Sendable>(
        _ endpoint: APIEndpoint, as type: Response.Type
    ) async throws -> Response
    func sendWithoutResponse(_ endpoint: APIEndpoint) async throws
}

nonisolated extension APIRequesting {
    func request<Response: Decodable & Sendable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: (any Encodable & Sendable)? = nil,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        timeout: TimeInterval? = nil,
        retryPolicy: APIRetryPolicy = .none,
        as type: Response.Type = Response.self
    ) async throws -> Response {
        let endpoint = try makeEndpoint(
            path: endpoint, method: method, body: body, queryItems: queryItems,
            headers: headers, timeout: timeout, retryPolicy: retryPolicy
        )
        return try await send(endpoint, as: type)
    }

    /// Successful DELETE/PUT responses may have no JSON body.
    func requestVoid(
        endpoint: String,
        method: HTTPMethod = .get,
        body: (any Encodable & Sendable)? = nil,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        timeout: TimeInterval? = nil,
        retryPolicy: APIRetryPolicy = .none
    ) async throws {
        let endpoint = try makeEndpoint(
            path: endpoint, method: method, body: body, queryItems: queryItems,
            headers: headers, timeout: timeout, retryPolicy: retryPolicy
        )
        try await sendWithoutResponse(endpoint)
    }

    private func makeEndpoint(
        path: String, method: HTTPMethod, body: (any Encodable & Sendable)?,
        queryItems: [URLQueryItem], headers: [String: String],
        timeout: TimeInterval?, retryPolicy: APIRetryPolicy
    ) throws -> APIEndpoint {
        var endpoint = APIEndpoint(path: path, method: method, queryItems: queryItems, headers: headers)
        if let body {
            do { endpoint.body = try JSONEncoder().encode(body) }
            catch { throw APIError.encodingFailed }
        }
        endpoint.timeout = timeout
        endpoint.retryPolicy = retryPolicy
        return endpoint
    }
}
