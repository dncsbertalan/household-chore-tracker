import Foundation

nonisolated struct LoginRequest: Encodable, Sendable {
    let email: String
    let password: String
}
