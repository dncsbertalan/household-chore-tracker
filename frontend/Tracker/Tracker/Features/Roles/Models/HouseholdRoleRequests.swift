import Foundation

nonisolated struct SaveHouseholdRoleRequest: Encodable, Equatable, Sendable {
    let name: String
    let permissions: [HouseholdPermission]
}
nonisolated struct UpdateHouseholdRoleRequest: Encodable, Equatable, Sendable {
    let name: String
    let permissions: [HouseholdPermission]
    let version: Int64
}
nonisolated struct AssignHouseholdRoleRequest: Encodable, Equatable, Sendable {
    let roleId: UUID
    let memberVersion: Int64
    let roleVersion: Int64
}
