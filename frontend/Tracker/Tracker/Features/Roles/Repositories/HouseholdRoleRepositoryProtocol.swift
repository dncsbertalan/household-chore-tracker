import Foundation

@MainActor
protocol HouseholdRoleRepositoryProtocol {
    func cachedRoles(householdId: UUID, accountId: UUID) async -> HouseholdRolesResponse?
    func roles(householdId: UUID, accountId: UUID) async throws -> HouseholdRolesResponse
    func createRole(householdId: UUID, accountId: UUID, request: SaveHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse
    func updateRole(householdId: UUID, roleId: UUID, accountId: UUID, request: UpdateHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse
    func deleteRole(householdId: UUID, roleId: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws -> HouseholdRolesResponse
    func removeMember(householdId: UUID, memberId: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws -> HouseholdMemberRemovalResponse
    func assignRole(householdId: UUID, memberId: UUID, accountId: UUID, request: AssignHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse
}

extension HouseholdRoleRepositoryProtocol {
    /// Remote-only and preview repositories have no persisted snapshot.
    func cachedRoles(householdId: UUID, accountId: UUID) async -> HouseholdRolesResponse? { nil }
}
