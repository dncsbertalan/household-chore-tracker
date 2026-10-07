import Foundation

nonisolated enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Paths are relative to the client's base URL (for example, `auth/csrf`).
nonisolated struct APIEndpoint: Sendable {
    let path: String
    var method: HTTPMethod = .get
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data?
    
    static func json<Body: Encodable>(
        _ path: String,
        method: HTTPMethod = .post,
        body: Body,
        headers: [String: String] = [:]
    ) throws -> APIEndpoint {
        do {
            return APIEndpoint(
                path: path, method: method, headers: headers,
                body: try JSONEncoder().encode(body)
            )
        } catch {
            throw APIError.encodingFailed
        }
    }
}
