import Foundation
import SwiftData

@MainActor
struct LocalHouseholdInvitationRepository: HouseholdInvitationRepositoryProtocol {
    let container: ModelContainer

    func invite(email: String, householdId: UUID, roleId: UUID, accountId: UUID) throws -> UUID {
        guard InviteHouseholdMemberRequest.isValidEmail(email) else { throw HouseholdInvitationError.invalidEmail }
        let context = makeContext()
        let household = try authorizedHousehold(householdId, accountId: accountId, in: context)
        guard household.householdRoles.contains(where: {
            $0.householdRoleId == roleId && $0.deletedAt == nil && $0.household.householdId == householdId
        }) else { throw HouseholdInvitationError.invalidRole }
        return try enqueue(.invite(householdId: householdId,
                                   request: InviteHouseholdMemberRequest(email: email, householdRoleId: roleId)),
                           action: .create, entityId: householdId, accountId: accountId, in: context)
    }

    func accept(_ invitation: HouseholdInvitationResponse, accountId: UUID) throws -> UUID {
        try respond(invitation, action: .accept, accountId: accountId)
    }

    func decline(_ invitation: HouseholdInvitationResponse, accountId: UUID) throws -> UUID {
        try respond(invitation, action: .decline, accountId: accountId)
    }

    func revoke(_ invitation: HouseholdInvitationResponse, accountId: UUID) throws -> UUID {
        let context = makeContext()
        _ = try authorizedHousehold(invitation.householdId, accountId: accountId, in: context)
        return try respond(invitation, action: .revoke, accountId: accountId, context: context)
    }

    func pending(accountId: UUID) throws -> [PendingHouseholdInvitation] {
        try entries(accountId: accountId, in: makeContext()).map {
            PendingHouseholdInvitation(id: $0.id, entityId: $0.entityId,
                                       action: $0.action, status: $0.status, lastError: $0.lastError)
        }
    }

    private func respond(_ invitation: HouseholdInvitationResponse, action: OutboxAction,
                         accountId: UUID, context: ModelContext? = nil) throws -> UUID {
        guard invitation.isValid, invitation.isPending() else { throw HouseholdInvitationError.notPending }
        return try enqueue(.respond(invitation: invitation), action: action, entityId: invitation.id,
                           accountId: accountId, in: context ?? makeContext())
    }

    private func enqueue(_ command: HouseholdInvitationCommand, action: OutboxAction,
                         entityId: UUID, accountId: UUID, in context: ModelContext) throws -> UUID {
        for entry in try entries(accountId: accountId, in: context) where entry.entityId == entityId {
            let existing = try JSONDecoder().decode(HouseholdInvitationCommand.self, from: entry.payload)
            if case .invite(_, let request) = command,
               case .invite(_, let saved) = existing, request.email != saved.email { continue }
            guard entry.action == action.rawValue, existing == command else { throw HouseholdInvitationError.alreadyQueued }
            return entry.id // Repeated taps keep the original operation and payload.
        }
        let operation = try OutboxOperation(accountId: accountId, entityType: .householdInvitation,
                                            entityId: entityId, action: action, payload: command)
        do {
            OutboxStore.enqueue(operation, in: context)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        NotificationCenter.default.post(name: .outboxDidEnqueue, object: nil)
        return operation.id
    }

    private func authorizedHousehold(_ id: UUID, accountId: UUID, in context: ModelContext) throws -> LocalHousehold {
        guard let household = try context.fetch(FetchDescriptor<LocalHousehold>(
            predicate: #Predicate { $0.householdId == id }
        )).first else { throw HouseholdAuthorizationError.permissionDenied(.memberInvite) }
        try HouseholdAuthorizationService().requirePermission(.memberInvite, in: household, userId: accountId)
        return household
    }

    private func entries(accountId: UUID, in context: ModelContext) throws -> [OutboxEntry] {
        let type = OutboxEntityType.householdInvitation.rawValue
        return try context.fetch(FetchDescriptor<OutboxEntry>(
            predicate: #Predicate { $0.accountId == accountId && $0.entityType == type },
            sortBy: [SortDescriptor(\.createdAt), SortDescriptor(\.id)]
        ))
    }

    private func makeContext() -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }
}
