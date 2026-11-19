import Foundation

actor PreviewHouseholdRoleRepository: HouseholdRoleRepositoryProtocol {
    private var saved: HouseholdRolesResponse?
    
    func create(householdId: UUID, request: SaveHouseholdRoleRequest, idempotencyKey: UUID) async throws -> HouseholdRolesResponse {
        let old = try await get(householdId: householdId).household
        let role = HouseholdRoleResponse(householdRoleId: UUID(), householdId: householdId, name: request.name,
            isSystemRole: false, permissions: request.permissions, createdAt: .now, updatedAt: .now, version: 0)
        let result = HouseholdRolesResponse(household: HouseholdResponse(householdId: old.id, name: old.name,
            description: old.description, members: old.members, roles: old.roles + [role], owner: old.owner, me: old.me, createdAt: old.createdAt),
            actions: .init(canView: true, canUpdate: true, canCreate: true))
        saved = result
        return result
    }

    func get(householdId: UUID) async throws -> HouseholdRolesResponse {
        if let saved { return saved }
        return HouseholdRolesResponse(household: try await PreviewHouseholdRepository().get(householdId: householdId),
                                      actions: .init(canView: true, canUpdate: true, canCreate: true))
    }
    
    func update(householdId: UUID, roleId: UUID, request: UpdateHouseholdRoleRequest, idempotencyKey: UUID) async throws -> HouseholdRolesResponse {
        let old = try await get(householdId: householdId).household
        let roles = old.roles.map { role in
            role.id == roleId ? HouseholdRoleResponse(householdRoleId: role.id, householdId: householdId,
                name: request.name, isSystemRole: role.isSystemRole, permissions: request.permissions,
                createdAt: role.createdAt, updatedAt: .now, version: role.version + 1) : role
        }
        let result = HouseholdRolesResponse(household: HouseholdResponse(householdId: old.id, name: old.name,
            description: old.description, members: old.members, roles: roles, owner: old.owner, me: old.me, createdAt: old.createdAt),
            actions: .init(canView: true, canUpdate: true, canCreate: true))
        saved = result
        return result
    }
}
