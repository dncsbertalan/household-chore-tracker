import Foundation

nonisolated struct LoginRequest: Encodable, Sendable {
    let email: String
    let password: String
}

nonisolated struct TokenResponse: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshExpiresIn: Int
}

/// A single persisted value keeps the token pair and expiry metadata consistent.
nonisolated struct StoredTokens: Codable, Sendable, Equatable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshExpiresIn: Int
    let issuedAt: Date
    // Persisted before refresh POST: a crash or lost response must not replay this token.
    var refreshPending: Bool? = nil

    var accessExpiresAt: Date { issuedAt.addingTimeInterval(TimeInterval(expiresIn)) }
    var refreshExpiresAt: Date { issuedAt.addingTimeInterval(TimeInterval(refreshExpiresIn)) }

    init(response: TokenResponse, issuedAt: Date) throws {
        guard response.tokenType == "Bearer", !response.accessToken.isEmpty,
              !response.refreshToken.isEmpty, response.expiresIn > 0,
              response.refreshExpiresIn >= 0,
              !response.accessToken.contains(where: { $0.isWhitespace || $0.isNewline }) else {
            throw APIError.invalidResponse
        }
        accessToken = response.accessToken
        refreshToken = response.refreshToken
        tokenType = response.tokenType
        expiresIn = response.expiresIn
        refreshExpiresIn = response.refreshExpiresIn
        self.issuedAt = issuedAt
    }
}
