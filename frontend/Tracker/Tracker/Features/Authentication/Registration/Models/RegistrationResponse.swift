import Foundation

nonisolated struct RegistrationResponse: Decodable, Sendable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
}
