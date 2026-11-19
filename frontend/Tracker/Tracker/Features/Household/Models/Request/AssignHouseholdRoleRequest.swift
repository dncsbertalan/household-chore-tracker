import Foundation

nonisolated struct AssignHouseholdRoleRequest: Encodable, Equatable, Sendable {
    let roleId: UUID
    let memberVersion: Int64
    let roleVersion: Int64
}
