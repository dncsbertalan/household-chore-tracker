import Foundation

nonisolated struct UpdateHouseholdRoleRequest: Encodable, Equatable, Sendable {
    let name: String
    let permissions: [HouseholdPermission]
    let version: Int64
}
