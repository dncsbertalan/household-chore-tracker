import Foundation

nonisolated struct InviteHouseholdMemberRequest: Encodable, Equatable, Sendable {
    let email: String
    let householdRoleId: UUID
}
