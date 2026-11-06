import Foundation

nonisolated struct CurrentUser: Decodable, Identifiable, Sendable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
}
