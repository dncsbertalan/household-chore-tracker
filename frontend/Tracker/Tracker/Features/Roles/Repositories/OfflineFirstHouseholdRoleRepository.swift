import Foundation

/// Cached reads and server-confirmed writes share one account/household scoped store.
/// Views decide when to refresh; connectivity failures never discard a valid snapshot.
@MainActor
final class OfflineFirstHouseholdRoleRepository: HouseholdRoleRepositoryProtocol {
    private let remote: any HouseholdRoleRepositoryProtocol
    private let local: any HouseholdRoleLocalStore
    private var snapshots: [HouseholdRolesScope: HouseholdRolesResponse] = [:]
    private var revisions: [HouseholdRolesScope: Int] = [:]
    private var writes: Set<HouseholdRolesScope> = []
    private var accountId: UUID?
    private var session = UUID()

    init(remote: any HouseholdRoleRepositoryProtocol, local: any HouseholdRoleLocalStore) {
        self.remote = remote
        self.local = local
    }

    /// Called synchronously at authentication boundaries so late responses cannot publish.
    /// Disk snapshots remain isolated by account and survive application restarts.
    func invalidateSession() {
        session = UUID()
        accountId = nil
        snapshots.removeAll()
        revisions.removeAll()
        writes.removeAll()
    }

    func cachedRoles(householdId: UUID, accountId: UUID) async -> HouseholdRolesResponse? {
        guard !Task.isCancelled else { return nil }
        let scope = activate(householdId, accountId)
        let session = session, revision = revisions[scope, default: 0]
        if let snapshot = snapshots[scope] { return snapshot }
        guard let snapshot = try? await local.load(scope),
              self.session == session, revisions[scope, default: 0] == revision,
              !Task.isCancelled else { return nil }
        snapshots[scope] = snapshot
        return snapshot
    }

    func roles(householdId: UUID, accountId: UUID) async throws -> HouseholdRolesResponse {
        try Task.checkCancellation()
        let scope = activate(householdId, accountId)
        guard !writes.contains(scope) else { throw CancellationError() }
        revisions[scope, default: 0] += 1
        let session = session, revision = revisions[scope, default: 0]
        do {
            let response = try await remote.roles(householdId: householdId, accountId: accountId)
            try verify(session, scope, revision)
            guard !writes.contains(scope) else { throw CancellationError() }
            try await persist(response, scope: scope, session: session, revision: revision)
            return response
        } catch {
            try await handle(error, scope: scope, session: session, revision: revision)
            throw error
        }
    }

    func createRole(householdId: UUID, accountId: UUID, request: SaveHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse {
        try await change(householdId, accountId) {
            try await self.remote.createRole(householdId: householdId, accountId: accountId, request: request, requestId: requestId)
        }
    }

    func updateRole(householdId: UUID, roleId: UUID, accountId: UUID, request: UpdateHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse {
        try await change(householdId, accountId) {
            try await self.remote.updateRole(householdId: householdId, roleId: roleId, accountId: accountId, request: request, requestId: requestId)
        }
    }

    func deleteRole(householdId: UUID, roleId: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws -> HouseholdRolesResponse {
        try await change(householdId, accountId) {
            try await self.remote.deleteRole(householdId: householdId, roleId: roleId, version: version, accountId: accountId, requestId: requestId)
        }
    }

    func assignRole(householdId: UUID, memberId: UUID, accountId: UUID, request: AssignHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse {
        try await change(householdId, accountId) {
            try await self.remote.assignRole(householdId: householdId, memberId: memberId, accountId: accountId, request: request, requestId: requestId)
        }
    }

    func removeMember(householdId: UUID, memberId: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws -> HouseholdMemberRemovalResponse {
        let scope = activate(householdId, accountId)
        try beginWrite(scope)
        let session = session, revision = revisions[scope, default: 0]
        defer { if self.session == session { writes.remove(scope) } }
        do {
            let response = try await remote.removeMember(householdId: householdId, memberId: memberId, version: version, accountId: accountId, requestId: requestId)
            try verify(session, scope, revision)
            guard response.householdId == householdId, response.removedMemberId == memberId else { throw APIError.invalidResponse }
            if let management = response.management {
                try await persist(management, scope: scope, session: session, revision: revision)
            } else {
                // A self-removal also invalidates any earlier in-flight reads.
                snapshots[scope] = nil
                try? await local.remove(scope)
                try verify(session, scope, revision)
            }
            return response
        } catch {
            try await handle(error, scope: scope, session: session, revision: revision)
            throw error
        }
    }

    private func change(_ householdId: UUID, _ accountId: UUID, operation: () async throws -> HouseholdRolesResponse) async throws -> HouseholdRolesResponse {
        let scope = activate(householdId, accountId)
        try beginWrite(scope)
        let session = session, revision = revisions[scope, default: 0]
        defer { if self.session == session { writes.remove(scope) } }
        do {
            let response = try await operation()
            try await persist(response, scope: scope, session: session, revision: revision)
            return response
        } catch {
            try await handle(error, scope: scope, session: session, revision: revision)
            throw error
        }
    }

    private func activate(_ householdId: UUID, _ accountId: UUID) -> HouseholdRolesScope {
        if self.accountId != accountId {
            invalidateSession()
            self.accountId = accountId
        }
        return .init(householdId: householdId, accountId: accountId)
    }

    private func beginWrite(_ scope: HouseholdRolesScope) throws {
        try Task.checkCancellation()
        guard !writes.contains(scope) else { throw CancellationError() }
        writes.insert(scope)
        revisions[scope, default: 0] += 1
    }

    private func verify(_ session: UUID, _ scope: HouseholdRolesScope, _ revision: Int) throws {
        try Task.checkCancellation()
        guard self.session == session, accountId == scope.accountId,
              revisions[scope, default: 0] == revision else { throw CancellationError() }
    }

    private func persist(_ response: HouseholdRolesResponse, scope: HouseholdRolesScope, session: UUID, revision: Int) async throws {
        try verify(session, scope, revision)
        guard response.household.id == scope.householdId else { throw APIError.invalidResponse }
        snapshots[scope] = response
        // Disk failure must not turn a committed server mutation into a failed save.
        try? await local.save(response, for: scope)
        try verify(session, scope, revision)
    }

    private func handle(_ error: Error, scope: HouseholdRolesScope, session: UUID, revision: Int) async throws {
        try verify(session, scope, revision)
        if HouseholdRoleFailure.invalidatesSnapshot(error) {
            snapshots[scope] = nil
            revisions[scope, default: 0] += 1
            try? await local.remove(scope)
        }
    }
}
