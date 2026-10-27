import Foundation

nonisolated struct JoinedHouseholdResponse: Decodable, Sendable {
    let householdId: UUID
    let name: String
    let description: String?
    let createdByUserId: UUID
    let version: Int64
    let roles: [HouseholdResponse.Role]
    let membership: HouseholdResponse.Member
}
