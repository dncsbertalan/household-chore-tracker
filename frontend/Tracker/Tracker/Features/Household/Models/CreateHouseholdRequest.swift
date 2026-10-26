import Foundation

nonisolated struct CreateHouseholdRequest: Codable, Sendable {
    let householdId: UUID
    let name: String
    let description: String?
    let roles: [Role]
    let creatorRoleId: UUID
    let householdMemberId: UUID
}
