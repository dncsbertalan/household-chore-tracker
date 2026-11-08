import Foundation

nonisolated struct TokenResponse: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshExpiresIn: Int
}
