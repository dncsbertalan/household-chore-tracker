import Foundation
import Observation

@MainActor
@Observable
final class HouseholdRoleAssignmentViewModel {
    let mutation = HouseholdRoleRequestState()
    let data: HouseholdRolesResponse
    let member: HouseholdMember
    var selectedRoleId: UUID
    private var attempt: (request: AssignHouseholdRoleRequest, id: UUID)?

    init(data: HouseholdRolesResponse, member: HouseholdMember) {
        self.data = data; self.member = member; selectedRoleId = member.householdRole.householdRoleId
    }
    var canSave: Bool { data.actions.canAssignRoles
        && selectedRoleId != member.householdRole.householdRoleId
        && data.household.roles.contains { $0.householdRoleId == selectedRoleId } }
    func save(accountId: UUID, using repository: any HouseholdRoleRepositoryProtocol) async -> HouseholdRolesResponse? {
        guard let operation = submission(accountId: accountId, using: repository) else { return nil }
        return await mutation.run(operation)
    }

    func submission(accountId: UUID, using repository: any HouseholdRoleRepositoryProtocol) -> (() async throws -> HouseholdRolesResponse)? {
        guard canSave, let role = data.household.roles.first(where: { $0.householdRoleId == selectedRoleId }) else { return nil }
        let request = AssignHouseholdRoleRequest(roleId: selectedRoleId, memberVersion: member.version, roleVersion: role.version)
        if attempt?.request != request { attempt = (request, UUID()) }
        guard let attempt else { return nil }
        let member = member
        return {
            try await repository.assignRole(householdId: member.householdId, memberId: member.householdMemberId,
                accountId: accountId, request: request, requestId: attempt.id)
        }
    }
}
