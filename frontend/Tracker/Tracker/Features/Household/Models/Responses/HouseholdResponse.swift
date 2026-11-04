import Foundation

nonisolated struct HouseholdResponse: Decodable, Sendable, Identifiable {
    let householdId: UUID
    let name: String
    let description: String?
    let createdByUserId: UUID
    let version: Int64
    let roles: [Role]
    let creatorMembership: Member?
    let members: [Member]

    var id: UUID { householdId }
}
