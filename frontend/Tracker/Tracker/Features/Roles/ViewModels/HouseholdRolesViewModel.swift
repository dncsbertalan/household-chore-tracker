import Foundation
import Observation

@MainActor
@Observable
final class HouseholdRolesViewModel {
    private(set) var data: HouseholdRolesResponse?
    private(set) var isLoading = false
    private(set) var busyMemberId: UUID?
    private(set) var hasLeftHousehold = false
    var isBusy: Bool { busyRoleId != nil || busyMemberId != nil }
    private var removal: (id: UUID, version: Int64, requestId: UUID)?
    private(set) var busyRoleId: UUID?
    private(set) var errorMessage: String?
    private(set) var actionError: String?
    private(set) var needsReload = false
    private var deletion: (id: UUID, version: Int64, requestId: UUID)?

    func load(householdId: UUID, accountId: UUID, using store: HouseholdStore) async {
        guard !isLoading, !isBusy else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do { apply(try await store.roles(householdId: householdId, accountId: accountId)) }
        catch is CancellationError { }
        catch { errorMessage = HouseholdRoleError(error).message }
    }
    func apply(_ response: HouseholdRolesResponse) {
        data = response
        actionError = nil
        needsReload = false
        deletion = nil
        removal = nil
    }
    func delete(_ role: HouseholdResponse.Role, accountId: UUID, using store: HouseholdStore) async {
        guard data?.actions.canDelete == true, !role.isSystemRole, !isBusy, !needsReload else { return }
        if deletion?.id != role.householdRoleId || deletion?.version != role.version {
            deletion = (role.householdRoleId, role.version, UUID())
        }
        guard let deletion else { return }
        busyRoleId = role.householdRoleId
        actionError = nil
        defer { busyRoleId = nil }
        do {
            apply(try await store.deleteRole(householdId: role.householdId, roleId: role.householdRoleId,
                version: role.version, accountId: accountId, requestId: deletion.requestId))
        } catch is CancellationError { }
        catch {
            let failure = HouseholdRoleError(error)
            actionError = failure.message
            needsReload = failure.needsReload
        }
    }

    func remove(_ member: HouseholdResponse.Member, accountId: UUID, using store: HouseholdStore) async {
        guard data?.actions.canRemoveMembers == true, !isBusy, !isLoading, !needsReload, !hasLeftHousehold else { return }
        if removal?.id != member.householdMemberId || removal?.version != member.version {
            removal = (member.householdMemberId, member.version, UUID())
        }
        guard let removal else { return }
        busyMemberId = member.householdMemberId
        actionError = nil
        defer { busyMemberId = nil }
        do {
            let response = try await store.removeMember(householdId: member.householdId, memberId: member.householdMemberId,
                version: member.version, accountId: accountId, requestId: removal.requestId)
            if let management = response.management { apply(management) }
            else { data = nil; hasLeftHousehold = true }
        } catch is CancellationError { }
        catch {
            let failure = HouseholdRoleError(error)
            actionError = failure.message
            needsReload = failure.needsReload
        }
    }
}
