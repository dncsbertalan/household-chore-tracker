import Foundation
import Observation

@MainActor
@Observable
final class HouseholdInvitationRepository: HouseholdInvitationRepositoryProtocol {
    private(set) var revision = 0
    private let service: any HouseholdInvitationServiceProtocol
    private let store: HouseholdStore
    private let lists = InvitationLists()
    private var session = UUID()
    private var actionRevision = 0

    init(service: any HouseholdInvitationServiceProtocol, store: HouseholdStore) {
        self.service = service
        self.store = store
    }

    func snapshot(accountId: UUID, householdId: UUID? = nil) -> InvitationLists.Snapshot? {
        _ = revision
        return lists.snapshot(accountId: accountId, householdId: householdId)
    }

    func load(accountId: UUID, householdId: UUID? = nil, refresh: Bool = false) async throws {
        let session = session
        let action = actionRevision
        let result: [HouseholdInvitationResponse]
        if let householdId { result = try await service.sent(householdId: householdId, accountId: accountId) }
        else { result = try await service.inbox(accountId: accountId) }
        try Task.checkCancellation()
        guard self.session == session, action == actionRevision else { throw CancellationError() }
        lists.save(result.filter { !store.isHouseholdDeleted($0.householdId) }, accountId: accountId, householdId: householdId)
        revision += 1
    }

    func refreshOnForeground(accountId: UUID) async {
        let session = session
        // Always refresh the inbox; refresh household lists only after they have been visited.
        let households = lists.householdIds(accountId: accountId)
        try? await load(accountId: accountId, refresh: true)
        for id in households {
            guard self.session == session, !Task.isCancelled else { return }
            try? await load(accountId: accountId, householdId: id, refresh: true)
        }
    }

    func removeHousehold(_ householdId: UUID) {
        lists.removeHousehold(householdId)
        didMutate()
    }

    func clearSession() {
        session = UUID()
        actionRevision += 1
        lists.clear()
        revision += 1
    }

    func invite(email: String, householdId: UUID, roleId: UUID, accountId: UUID,
                requestId: UUID) async throws -> HouseholdInvitationResponse {
        guard let household = store.household(id: householdId),
              HouseholdAuthorizationService().hasPermission(.memberInvite, in: household, userId: accountId) else {
            throw HouseholdAuthorizationError.permissionDenied(.memberInvite)
        }
        guard household.roles.contains(where: { $0.householdRoleId == roleId }) else { throw HouseholdInvitationError.invalidRole }
        let session = session
        let response = try await service.invite(email: email, householdId: householdId, roleId: roleId,
                                                accountId: accountId, requestId: requestId)
        try Task.checkCancellation()
        guard self.session == session else { throw CancellationError() }
        guard !store.isHouseholdDeleted(response.householdId) else { throw CancellationError() }
        lists.record(response, accountId: accountId)
        didMutate()
        return response
    }

    func accept(_ invitation: HouseholdInvitationResponse, accountId: UUID, requestId: UUID) async throws {
        let session = session
        let response = try await service.accept(invitation, accountId: accountId, requestId: requestId)
        try Task.checkCancellation()
        guard self.session == session else { throw CancellationError() }
        guard !store.isHouseholdDeleted(response.householdId) else { throw CancellationError() }
        store.record(Household(householdId: response.householdId, name: response.name,
            description: response.description, createdByUserId: response.createdByUserId, version: response.version,
            roles: response.roles, creatorMembership: nil, members: [response.membership]))
        lists.remove(id: invitation.id, accountId: accountId)
        didMutate()
    }

    func decline(_ invitation: HouseholdInvitationResponse, accountId: UUID, requestId: UUID) async throws {
        let session = session
        let response = try await service.decline(invitation, accountId: accountId, requestId: requestId)
        try Task.checkCancellation()
        guard self.session == session else { throw CancellationError() }
        guard !store.isHouseholdDeleted(response.householdId) else { throw CancellationError() }
        lists.record(response, accountId: accountId)
        didMutate()
    }

    func revoke(_ invitation: HouseholdInvitationResponse, accountId: UUID, requestId: UUID) async throws {
        let session = session
        try await service.revoke(invitation, accountId: accountId, requestId: requestId)
        try Task.checkCancellation()
        guard self.session == session else { throw CancellationError() }
        lists.remove(id: invitation.id, accountId: accountId)
        didMutate()
    }

    private func didMutate() {
        actionRevision += 1
        revision += 1
    }

}
