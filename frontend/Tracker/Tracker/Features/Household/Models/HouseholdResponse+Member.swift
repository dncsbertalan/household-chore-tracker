import Foundation

extension HouseholdResponse {
    nonisolated struct Member: Decodable, Sendable {
        let householdMemberId: UUID
        let householdId: UUID
        let userId: UUID
        let nickname: String?
        let householdRole: Role
        let joinedAt: String
        let version: Int64
    }
}
