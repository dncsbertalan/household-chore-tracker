import Foundation

nonisolated struct APIEndpoint: Sendable {
    let path: String
    var method: HTTPMethod = .get
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data?
    /// Bind durable commands to the authenticated account that created them.
    var expectedAccountId: UUID?
    var timeout: TimeInterval?
    var retryPolicy: APIRetryPolicy = .none

    static func json<Body: Encodable>(
        _ path: String,
        method: HTTPMethod = .post,
        body: Body,
        headers: [String: String] = [:]
    ) throws -> APIEndpoint {
        do {
            return APIEndpoint(
                path: path,
                method: method,
                headers: headers,
                body: try JSONEncoder().encode(body)
            )
        } catch {
            throw APIError.encodingFailed
        }
    }
}
