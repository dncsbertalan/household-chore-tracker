import Foundation

extension CreateHouseholdRequest {
    nonisolated struct Role: Codable, Sendable {
        let householdRoleId: UUID
        let name: String
        let permissions: [HouseholdPermission]
    }
}
