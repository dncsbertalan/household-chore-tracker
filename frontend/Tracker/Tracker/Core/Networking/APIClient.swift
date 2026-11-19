//
//  APIClient.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import Foundation

final class APIClient: Sendable {
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let baseURL: URL
    private let tokenStore: any TokenStoreProtocol
    private let tokenRefresher: TokenRefresher

    init(
        baseURL: URL = URL(string: "http://localhost:8080")!,
        session: URLSession = .shared,
        tokenStore: any TokenStoreProtocol
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStore = tokenStore
        self.tokenRefresher = TokenRefresher(baseURL: baseURL, session: session, tokenStore: tokenStore)

        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Request with response
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        let data = try await execute(endpoint: endpoint, method: method, body: body, queryItems: queryItems, headers: headers)

        // Decode response
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
    
    // MARK: - Request without response
    func request(
        endpoint: String,
        method: HTTPMethod = .get,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil
    ) async throws {
        _ = try await execute(endpoint: endpoint, method: method, body: body, queryItems: queryItems, headers: headers)
    }

    // MARK: - Core request execution
    func execute(
        endpoint: String,
        method: HTTPMethod = .get,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil
    ) async throws -> Data {
        var url = baseURL.appendingPathComponent(endpoint)

        // Append query parameters
        if let queryItems, !queryItems.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            components.queryItems = queryItems
            url = components.url!
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        // Inject auth token if available
        let isAuthRequest = url.path.contains("/auth/")
        var accessToken: String?
        if !isAuthRequest {
            accessToken = try await tokenRefresher.accessToken()
            if let accessToken {
                urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            }
        }

        // Merge custom headers
        headers?.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }

        // Encode body
        if let body {
            urlRequest.httpBody = try encoder.encode(body)
        }

        // Execute request
        var (data, response) = try await session.data(for: urlRequest)
        if (response as? HTTPURLResponse)?.statusCode == 401, !isAuthRequest,
           let accessToken, urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer \(accessToken)" {
            let refreshed = try await tokenRefresher.accessToken(rejected: accessToken)
            try Task.checkCancellation()
            guard let refreshed else { throw APIError.unauthorized }
            // Retry the exact request once, retaining its body and idempotency key.
            urlRequest.setValue("Bearer \(refreshed)", forHTTPHeaderField: "Authorization")
            (data, response) = try await session.data(for: urlRequest)
        }

        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Map status codes to errors
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.from(statusCode: httpResponse.statusCode, data: data)
        }

        return data
    }
}
