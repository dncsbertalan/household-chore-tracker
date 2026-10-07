import Foundation

nonisolated struct RegistrationRequest: Encodable, Sendable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
}

nonisolated struct RegistrationResponse: Decodable, Sendable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
}

