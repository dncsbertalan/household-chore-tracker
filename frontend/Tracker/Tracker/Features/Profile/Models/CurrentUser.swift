import Foundation

/// Matches GET /api/v1/users/me; separate from persistence and registration DTOs.
nonisolated struct CurrentUser: Decodable, Identifiable, Sendable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
}
