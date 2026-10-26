import Foundation

extension HouseholdResponse {
    nonisolated struct Role: Decodable, Sendable, Equatable {
        let householdRoleId: UUID
        let householdId: UUID
        let name: String
        let isSystemRole: Bool
        let permissions: [Permission]
        let version: Int64
    }
}
