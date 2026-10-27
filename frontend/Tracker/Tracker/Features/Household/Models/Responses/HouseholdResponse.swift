import Foundation

nonisolated struct HouseholdResponse: Decodable, Sendable {
    let householdId: UUID
    let name: String
    let description: String?
    let createdByUserId: UUID
    let version: Int64
    let roles: [Role]
    let creatorMembership: Member
}
