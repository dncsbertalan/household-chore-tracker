import Foundation

nonisolated struct SaveHouseholdRoleRequest: Encodable, Sendable {
    let name: String
    let permissions: [HouseholdPermission]
}
