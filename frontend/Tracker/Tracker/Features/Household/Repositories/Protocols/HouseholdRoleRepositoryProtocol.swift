import Foundation

nonisolated protocol HouseholdRoleRepositoryProtocol: Sendable {
    func create(householdId: UUID, request: SaveHouseholdRoleRequest, idempotencyKey: UUID) async throws -> HouseholdRolesResponse
    func get(householdId: UUID) async throws -> HouseholdRolesResponse
    func update(householdId: UUID, roleId: UUID, request: UpdateHouseholdRoleRequest, idempotencyKey: UUID) async throws -> HouseholdRolesResponse
}
