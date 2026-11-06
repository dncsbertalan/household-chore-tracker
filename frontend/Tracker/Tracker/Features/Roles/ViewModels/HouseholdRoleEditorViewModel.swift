import Foundation
import Observation

@MainActor
@Observable
final class HouseholdRoleEditorViewModel {
    let mutation = HouseholdRoleRequestState()
    let data: HouseholdRolesResponse
    let role: HouseholdRole?
    var name: String
    var selectedPermissions: Set<HouseholdPermission>
    private var attempt: (request: SaveHouseholdRoleRequest, id: UUID)?

    init(data: HouseholdRolesResponse, role: HouseholdRole?) {
        self.data = data
        self.role = role
        name = role?.name ?? ""
        selectedPermissions = Set(role?.permissions.map(\.name) ?? data.permissions.map(\.name))
    }
    var isEditable: Bool { role.map { data.actions.canUpdate && !$0.isSystemRole } ?? data.actions.canCreate }
    var canSave: Bool { isEditable && HouseholdConstraints.isValidRoleName(name)
        && selectedPermissions.isSubset(of: Set(data.permissions.map(\.name))) }

    func save(accountId: UUID, using repository: any HouseholdRoleRepositoryProtocol) async -> HouseholdRolesResponse? {
        guard let operation = submission(accountId: accountId, using: repository) else { return nil }
        return await mutation.run(operation)
    }

    func submission(accountId: UUID, using repository: any HouseholdRoleRepositoryProtocol) -> (() async throws -> HouseholdRolesResponse)? {
        guard canSave else { return nil }
        let request = SaveHouseholdRoleRequest(name: HouseholdConstraints.trimmedText(name),
            permissions: HouseholdPermission.allCases.filter { selectedPermissions.contains($0) })
        if attempt?.request != request { attempt = (request, UUID()) }
        guard let attempt else { return nil }
        let householdId = data.household.id
        let role = role
        return {
            if let role {
                return try await repository.updateRole(householdId: householdId, roleId: role.householdRoleId,
                    accountId: accountId, request: .init(name: request.name, permissions: request.permissions, version: role.version), requestId: attempt.id)
            }
            return try await repository.createRole(householdId: householdId, accountId: accountId,
                request: request, requestId: attempt.id)
        }
    }
}
