import Foundation
import Observation

@MainActor
@Observable
final class SendHouseholdInvitationViewModel {
    var email = ""
    var selectedRoleId: UUID?
    private(set) var queuedOperationId: UUID?
    private(set) var errorMessage: String?

    var canSend: Bool {
        queuedOperationId == nil && selectedRoleId != nil && InviteHouseholdMemberRequest.isValidEmail(email)
    }

    func send(householdId: UUID, accountId: UUID, using repository: any HouseholdInvitationRepositoryProtocol) {
        guard queuedOperationId == nil else { return }
        errorMessage = nil
        guard InviteHouseholdMemberRequest.isValidEmail(email) else {
            errorMessage = HouseholdInvitationError.invalidEmail.localizedDescription
            return
        }
        guard let selectedRoleId else {
            errorMessage = HouseholdInvitationError.invalidRole.localizedDescription
            return
        }
        do {
            queuedOperationId = try repository.invite(email: email, householdId: householdId,
                                                      roleId: selectedRoleId, accountId: accountId)
        } catch { errorMessage = error.localizedDescription }
    }
}
