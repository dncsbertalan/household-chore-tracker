import Foundation

/// Shared interface for public and authenticated clients, and feature-service test doubles.
nonisolated protocol APIClientProtocol: Sendable {
    /// Sends a prepared endpoint and decodes its successful JSON response.
    ///
    /// - Parameters:
    ///   - endpoint: The request path, method, encoded body, and request options.
    ///   - type: The type to decode from the response body.
    /// - Returns: The decoded response.
    /// - Throws: Request, transport, HTTP, or decoding errors, and cancellation.
    func send<Response: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        as type: Response.Type
    ) async throws -> Response

    /// Sends a prepared endpoint and validates success without decoding its body.
    ///
    /// Use for empty responses, including HTTP 204, or when the body is unused.
    /// - Parameter endpoint: The prepared request and its options.
    /// - Throws: Request, transport, or HTTP errors, and cancellation.
    func sendWithoutResponse(_ endpoint: APIEndpoint) async throws
}

nonisolated extension APIClientProtocol {
    /// Builds a request, JSON-encodes any body, and decodes the successful response.
    ///
    /// - Parameters:
    ///   - endpoint: A relative API path without a leading slash or embedded query.
    ///   - method: The HTTP method; defaults to GET.
    ///   - body: An optional value to encode as the JSON request body.
    ///   - queryItems: Query parameters encoded separately from the path.
    ///   - headers: Request headers, overriding matching client defaults.
    ///   - timeout: A positive, finite timeout in seconds, or `nil` for the client default.
    ///   - retryPolicy: The retry policy; defaults to no retries.
    ///   - type: The response type, inferred from the return type when omitted.
    /// - Returns: The decoded response.
    /// - Throws: `APIError.encodingFailed` if body encoding fails, or errors from `send(_:as:)`.
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
            path: endpoint,
            method: method,
            body: body,
            queryItems: queryItems,
            headers: headers,
            timeout: timeout,
            retryPolicy: retryPolicy
        )
        return try await send(endpoint, as: type)
    }

    /// Builds a request, JSON-encodes any body, and validates success without decoding a response.
    ///
    /// Use for endpoints that return no JSON body or whose response body is unused.
    /// Parameters follow `request(endpoint:method:body:queryItems:headers:timeout:retryPolicy:as:)`,
    /// including the default GET method and no retries.
    /// - Throws: `APIError.encodingFailed` if body encoding fails, or errors from `sendWithoutResponse(_:)`.
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
            path: endpoint,
            method: method,
            body: body,
            queryItems: queryItems,
            headers: headers,
            timeout: timeout,
            retryPolicy: retryPolicy
        )
        try await sendWithoutResponse(endpoint)
    }

    /// Combines request options into an endpoint, encoding any body as JSON.
    /// - Throws: `APIError.encodingFailed` if the supplied body cannot be encoded.
    private func makeEndpoint(
        path: String,
        method: HTTPMethod,
        body: (any Encodable & Sendable)?,
        queryItems: [URLQueryItem],
        headers: [String: String],
        timeout: TimeInterval?,
        retryPolicy: APIRetryPolicy
    ) throws -> APIEndpoint {
        var endpoint = APIEndpoint(
            path: path,
            method: method,
            queryItems: queryItems,
            headers: headers
        )
        if let body {
            do { endpoint.body = try JSONEncoder().encode(body) } catch {
                throw APIError.encodingFailed
            }
        }
        endpoint.timeout = timeout
        endpoint.retryPolicy = retryPolicy
        return endpoint
    }
}
