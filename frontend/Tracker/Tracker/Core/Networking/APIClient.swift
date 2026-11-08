//
//  APIClient.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import Foundation

final class APIClient: Sendable {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let baseURL: URL
    private let tokenStore: any TokenStoreProtocol

    init(
        baseURL: URL = URL(string: "http://localhost:8080")!,
        session: URLSession = .shared,
        tokenStore: any TokenStoreProtocol = KeychainTokenStore.shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStore = tokenStore

        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Core request method
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
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
        if let tokens = try await tokenStore.load() {
            urlRequest.setValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
        }

        // Merge custom headers
        headers?.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }

        // Encode body
        if let body {
            urlRequest.httpBody = try encoder.encode(body)
        }

        // Execute request
        let (data, response) = try await session.data(for: urlRequest)

        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Map status codes to errors
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.from(statusCode: httpResponse.statusCode, data: data)
        }

        // Decode response
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}
