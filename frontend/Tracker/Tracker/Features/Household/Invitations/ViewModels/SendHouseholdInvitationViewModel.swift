import Foundation
import Observation

@MainActor
@Observable
final class SendHouseholdInvitationViewModel {
    var email = ""
    var selectedRoleId: UUID?
    private(set) var isSending = false
    private(set) var errorMessage: String?
    private var attempt: (email: String, roleId: UUID, householdId: UUID, accountId: UUID, id: UUID)?

    var canSend: Bool {
        !isSending && selectedRoleId != nil && InviteHouseholdMemberRequest.isValidEmail(email)
    }

    func send(householdId: UUID, accountId: UUID, using repository: any HouseholdInvitationRepositoryProtocol) async -> Bool {
        guard !isSending else { return false }
        errorMessage = nil
        guard InviteHouseholdMemberRequest.isValidEmail(email) else {
            errorMessage = HouseholdInvitationError.invalidEmail.localizedDescription
            return false
        }
        guard let roleId = selectedRoleId else {
            errorMessage = HouseholdInvitationError.invalidRole.localizedDescription
            return false
        }
        let normalized = InviteHouseholdMemberRequest.normalizedEmail(email)
        if attempt?.email != normalized || attempt?.roleId != roleId || attempt?.householdId != householdId || attempt?.accountId != accountId {
            attempt = (normalized, roleId, householdId, accountId, UUID())
        }
        guard let attempt else { return false }
        isSending = true
        defer { isSending = false }
        do {
            _ = try await repository.invite(email: normalized, householdId: householdId, roleId: roleId,
                                             accountId: accountId, requestId: attempt.id)
            return true
        } catch is CancellationError {
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
