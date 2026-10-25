import Foundation

/// Share one client between feature services. Actor isolation keeps decoding off the UI actor.
actor APIClient: APIClientProtocol {
    private let configuration: APIConfiguration
    private let transport: any HTTPTransportProtocol
    private let sleep: @Sendable (TimeInterval) async throws -> Void

    init(configuration: APIConfiguration, session: URLSession? = nil) {
        self.configuration = configuration
        self.transport = URLSessionTransport(
            session: session ?? Self.makeSession()
        )
        self.sleep = { try await Task.sleep(for: .seconds($0)) }
    }

    init(
        configuration: APIConfiguration,
        transport: any HTTPTransportProtocol,
        sleep: @escaping @Sendable (TimeInterval) async throws -> Void = {
            try await Task.sleep(for: .seconds($0))
        }
    ) {
        self.configuration = configuration
        self.transport = transport
        self.sleep = sleep
    }

    func send<Response: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        as type: Response.Type = Response.self
    ) async throws -> Response {
        let data = try await execute(endpoint)
        do {
            // Preserve the backend's camelCase JSON names. Date formats belong to DTOs.
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    /// For successful responses whose body is intentionally unused, including HTTP 204.
    func sendWithoutResponse(_ endpoint: APIEndpoint) async throws {
        _ = try await execute(endpoint)
    }

    private func execute(_ endpoint: APIEndpoint) async throws -> Data {
        var attempt = 1
        while true {
            do { return try await executeOnce(endpoint) } catch {
                try Task.checkCancellation()
                guard
                    let delay = endpoint.retryPolicy.delay(
                        afterAttempt: attempt,
                        method: endpoint.method,
                        error: error
                    )
                else { throw error }
                try await sleep(delay)
                attempt += 1
            }
        }
    }

    private func executeOnce(_ endpoint: APIEndpoint) async throws -> Data {
        try Task.checkCancellation()
        let request = try makeRequest(endpoint)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.data(for: request)
        } catch let error as URLError {
            if error.code == .cancelled || Task.isCancelled {
                throw CancellationError()
            }
            throw APIError.transport(error.code)
        }
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(response.statusCode) else {
            let problem = try? JSONDecoder().decode(APIProblem.self, from: data)
            throw APIError.http(
                statusCode: response.statusCode,
                problem: problem
            )
        }
        return data
    }

    private func makeRequest(_ endpoint: APIEndpoint) throws -> URLRequest {
        // Reject absolute URLs, traversal and embedded queries. Query values are encoded separately.
        let segments = endpoint.path.split(
            separator: "/",
            omittingEmptySubsequences: false
        )
        guard !endpoint.path.isEmpty,
            segments.allSatisfy({
                !$0.isEmpty && $0 != "." && $0 != ".."
            }), !endpoint.path.contains(where: { "%?#:\\".contains($0) })
        else {
            throw APIError.invalidEndpoint
        }
        let url = configuration.baseURL.appendingPathComponent(endpoint.path)
        guard
            var components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )
        else {
            throw APIError.invalidEndpoint
        }
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }
        guard let url = components.url else { throw APIError.invalidEndpoint }
        var request = URLRequest(url: url)
        if let timeout = endpoint.timeout {
            guard timeout.isFinite, timeout > 0 else {
                throw APIError.invalidEndpoint
            }
            request.timeoutInterval = timeout
        }
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if endpoint.body != nil {
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
        }
        for (name, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: name)
        }
        return request
    }

    nonisolated private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        // Retains CSRF session cookies in memory without persisting auth responses to disk.
        configuration.httpShouldSetCookies = true
        configuration.httpCookieAcceptPolicy = .onlyFromMainDocumentDomain
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        return URLSession(
            configuration: configuration,
            delegate: APIRedirectPolicy(),
            delegateQueue: nil
        )
    }
}
