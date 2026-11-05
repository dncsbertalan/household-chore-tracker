import Foundation

nonisolated struct HouseholdMemberRemovalResponse: Decodable, Sendable {
    let householdId: UUID
    let removedMemberId: UUID
    /// Absent when the authenticated caller removed their own membership.
    let management: HouseholdRolesResponse?
}
