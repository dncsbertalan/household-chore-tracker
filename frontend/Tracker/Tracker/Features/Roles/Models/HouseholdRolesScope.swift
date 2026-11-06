import Foundation

nonisolated struct HouseholdRolesScope: Hashable, Codable, Sendable {
    let householdId: UUID
    let accountId: UUID
}
