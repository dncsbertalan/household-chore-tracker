import Foundation
import Observation

@MainActor
@Observable
final class HouseholdRolesViewModel {
    private(set) var data: HouseholdRolesResponse?
    private(set) var isRefreshing = false
    private(set) var loadError: String?
    private(set) var actionFailure: HouseholdRoleError?
    private(set) var busyRoleId: UUID?
    private(set) var busyMemberId: UUID?
    private(set) var hasLeftHousehold = false
    var isBusy: Bool { busyRoleId != nil || busyMemberId != nil }
    var isLoading: Bool { data == nil && isRefreshing }
    var needsReload: Bool { actionFailure?.needsReload == true }
    private var revision = 0
    private var deletion: (id: UUID, version: Int64, requestId: UUID)?
    private var removal: (id: UUID, version: Int64, requestId: UUID)?

    func load(householdId: UUID, accountId: UUID, using repository: any HouseholdRoleRepositoryProtocol) async {
        guard !isRefreshing, !isBusy, !hasLeftHousehold else { return }
        isRefreshing = true
        loadError = nil
        let revision = revision
        defer { isRefreshing = false }
        if data == nil {
            let cached = await repository.cachedRoles(householdId: householdId, accountId: accountId)
            guard !Task.isCancelled, self.revision == revision else { return }
            data = cached
        }
        do {
            let response = try await repository.roles(householdId: householdId, accountId: accountId)
            try Task.checkCancellation()
            guard self.revision == revision else { return }
            accept(response)
        } catch {
            guard self.revision == revision, !HouseholdRoleFailure.isCancellation(error) else { return }
            if HouseholdRoleFailure.invalidatesSnapshot(error) { data = nil }
            // Keep the offline snapshot visible only for connection/server failures.
            if data == nil { loadError = HouseholdRoleError(error).message }
            else if !HouseholdRoleFailure.canUseCachedData(after: error) {
                actionFailure = HouseholdRoleError(error)
            }
        }
    }

    func accept(_ response: HouseholdRolesResponse) {
        revision += 1
        data = response
        loadError = nil
        actionFailure = nil
        resetAttempts()
    }

    func delete(_ role: HouseholdRole, accountId: UUID, using repository: any HouseholdRoleRepositoryProtocol) async {
        guard data?.actions.canDelete == true, !role.isSystemRole, !isBusy, !isLoading, !needsReload else { return }
        busyRoleId = role.householdRoleId
        actionFailure = nil
        revision += 1
        defer { busyRoleId = nil }
        do {
            let response = try await deletionOperation(role, accountId: accountId, using: repository)()
            try Task.checkCancellation()
            accept(response)
        } catch { recordFailure(error) }
    }

    func remove(_ member: HouseholdMember, accountId: UUID, using repository: any HouseholdRoleRepositoryProtocol) async {
        guard data?.actions.canRemoveMembers == true, !isBusy, !isLoading, !needsReload, !hasLeftHousehold else { return }
        busyMemberId = member.householdMemberId
        actionFailure = nil
        revision += 1
        defer { busyMemberId = nil }
        do {
            let response = try await removalOperation(member, accountId: accountId, using: repository)()
            try Task.checkCancellation()
            if let management = response.management { accept(management) }
            else { data = nil; hasLeftHousehold = true }
        } catch { recordFailure(error) }
    }

    private func recordFailure(_ error: Error) {
        guard !HouseholdRoleFailure.isCancellation(error) else { return }
        actionFailure = HouseholdRoleError(error)
        if HouseholdRoleFailure.invalidatesSnapshot(error) {
            data = nil
            loadError = actionFailure?.message
        }
    }

    func resetAttempts() {
        deletion = nil
        removal = nil
    }

    func deletionOperation(_ role: HouseholdRole, accountId: UUID,
                           using repository: any HouseholdRoleRepositoryProtocol) -> () async throws -> HouseholdRolesResponse {
        if deletion?.id != role.householdRoleId || deletion?.version != role.version {
            deletion = (role.householdRoleId, role.version, UUID())
        }
        let requestId = deletion!.requestId
        return {
            try await repository.deleteRole(householdId: role.householdId, roleId: role.householdRoleId,
                version: role.version, accountId: accountId, requestId: requestId)
        }
    }

    func removalOperation(_ member: HouseholdMember, accountId: UUID,
                          using repository: any HouseholdRoleRepositoryProtocol) -> () async throws -> HouseholdMemberRemovalResponse {
        if removal?.id != member.householdMemberId || removal?.version != member.version {
            removal = (member.householdMemberId, member.version, UUID())
        }
        let requestId = removal!.requestId
        return {
            try await repository.removeMember(householdId: member.householdId, memberId: member.householdMemberId,
                version: member.version, accountId: accountId, requestId: requestId)
        }
    }
}
