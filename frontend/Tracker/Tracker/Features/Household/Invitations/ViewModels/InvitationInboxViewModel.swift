import Foundation
import Observation

@MainActor
@Observable
final class InvitationInboxViewModel {
    private(set) var invitations: [HouseholdInvitationResponse] = []
    private(set) var pendingOperations: [PendingHouseholdInvitation] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    let accountId: UUID
    private let service: any HouseholdInvitationServiceProtocol
    private let repository: any HouseholdInvitationRepositoryProtocol

    init(accountId: UUID, service: any HouseholdInvitationServiceProtocol,
         repository: any HouseholdInvitationRepositoryProtocol) {
        self.accountId = accountId
        self.service = service
        self.repository = repository
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            refreshPending()
            let result = try await service.inbox(accountId: accountId)
            try Task.checkCancellation()
            invitations = result
            refreshPending()
        } catch is CancellationError {
            // A dismissed screen must not publish a late result or a cancellation error.
        } catch { errorMessage = error.localizedDescription }
    }

    func canRespond(to invitation: HouseholdInvitationResponse, at date: Date = .now) -> Bool {
        invitation.isPending(at: date) && !pendingOperations.contains { $0.entityId == invitation.id }
    }

    func accept(_ invitation: HouseholdInvitationResponse) {
        respond(to: invitation, accepting: true)
    }

    func decline(_ invitation: HouseholdInvitationResponse) {
        respond(to: invitation, accepting: false)
    }

    func refreshPending() {
        do { pendingOperations = try repository.pending(accountId: accountId) }
        catch { errorMessage = error.localizedDescription }
    }

    private func respond(to invitation: HouseholdInvitationResponse, accepting: Bool) {
        errorMessage = nil
        do {
            if accepting { _ = try repository.accept(invitation, accountId: accountId) }
            else { _ = try repository.decline(invitation, accountId: accountId) }
            // Queued is not accepted: membership appears only after successful delivery and local import.
            pendingOperations = try repository.pending(accountId: accountId)
        } catch { errorMessage = error.localizedDescription }
    }
}
