import Foundation
import Observation

@MainActor
@Observable
final class HouseholdRoleAssignmentViewModel {
    let data: HouseholdRolesResponse
    let member: HouseholdResponse.Member
    var selectedRoleId: UUID
    private(set) var isSaving = false
    private(set) var errorMessage: String?
    private(set) var needsReload = false
    private var attempt: (request: AssignHouseholdRoleRequest, id: UUID)?

    init(data: HouseholdRolesResponse, member: HouseholdResponse.Member) {
        self.data = data; self.member = member; selectedRoleId = member.householdRole.householdRoleId
    }
    var canSave: Bool { data.actions.canAssignRoles && !isSaving && !needsReload
        && selectedRoleId != member.householdRole.householdRoleId
        && data.household.roles.contains { $0.householdRoleId == selectedRoleId } }
    func save(accountId: UUID, using store: HouseholdStore) async -> HouseholdRolesResponse? {
        guard canSave, let role = data.household.roles.first(where: { $0.householdRoleId == selectedRoleId }) else { return nil }
        let request = AssignHouseholdRoleRequest(roleId: selectedRoleId, memberVersion: member.version, roleVersion: role.version)
        if attempt?.request != request { attempt = (request, UUID()) }
        guard let attempt else { return nil }
        isSaving = true; errorMessage = nil
        defer { isSaving = false }
        do {
            return try await store.assignRole(householdId: member.householdId, memberId: member.householdMemberId,
                accountId: accountId, request: request, requestId: attempt.id)
        } catch is CancellationError { return nil }
        catch {
            let failure = HouseholdRoleError(error)
            errorMessage = failure.message; needsReload = failure.needsReload
            return nil
        }
    }
}
