import Foundation
import Observation

@MainActor
@Observable
final class HouseholdRoleEditorViewModel {
    let data: HouseholdRolesResponse
    let role: HouseholdResponse.Role?
    var name: String
    var selectedPermissions: Set<HouseholdPermission>
    private(set) var isSaving = false
    private(set) var errorMessage: String?
    private(set) var needsReload = false
    private var attempt: (request: SaveHouseholdRoleRequest, id: UUID)?

    init(data: HouseholdRolesResponse, role: HouseholdResponse.Role?) {
        self.data = data
        self.role = role
        name = role?.name ?? ""
        selectedPermissions = Set(role?.permissions.map(\.name) ?? [])
    }
    var isEditable: Bool { role.map { data.actions.canUpdate && !$0.isSystemRole } ?? data.actions.canCreate }
    var canSave: Bool { isEditable && !isSaving && !needsReload && HouseholdConstraints.isValidRoleName(name)
        && selectedPermissions.isSubset(of: Set(data.permissions.map(\.name))) }

    func save(accountId: UUID, using store: HouseholdStore) async -> HouseholdRolesResponse? {
        guard canSave else { return nil }
        let request = SaveHouseholdRoleRequest(name: HouseholdConstraints.trimmedText(name),
            permissions: HouseholdPermission.allCases.filter { selectedPermissions.contains($0) })
        if attempt?.request != request { attempt = (request, UUID()) }
        guard let attempt else { return nil }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            if let role {
                return try await store.updateRole(householdId: role.householdId, roleId: role.householdRoleId,
                    accountId: accountId, request: .init(name: request.name, permissions: request.permissions, version: role.version), requestId: attempt.id)
            }
            return try await store.createRole(householdId: data.household.id, accountId: accountId, request: request, requestId: attempt.id)
        } catch is CancellationError { return nil }
        catch {
            let failure = HouseholdRoleError(error)
            errorMessage = failure.message
            needsReload = failure.needsReload
            return nil
        }
    }
}
