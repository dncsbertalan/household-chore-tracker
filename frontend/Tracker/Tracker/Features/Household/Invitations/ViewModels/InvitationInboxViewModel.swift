import Foundation
import Observation

@MainActor
@Observable
final class InvitationInboxViewModel {
    let accountId: UUID
    let householdId: UUID?
    private let repository: HouseholdInvitationRepository
    private(set) var isLoading = false
    private(set) var activeInvitationId: UUID?
    private(set) var errorMessage: String?
    private var attempts: [UUID: (action: String, id: UUID)] = [:]

    var invitations: [HouseholdInvitationResponse] {
        repository.snapshot(accountId: accountId, householdId: householdId)?.invitations ?? []
    }
    var fetchedAt: Date? { repository.snapshot(accountId: accountId, householdId: householdId)?.fetchedAt }

    init(accountId: UUID, householdId: UUID? = nil, repository: HouseholdInvitationRepository) {
        self.accountId = accountId
        self.householdId = householdId
        self.repository = repository
    }

    func load(refresh: Bool = false) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do { try await repository.load(accountId: accountId, householdId: householdId, refresh: refresh) }
        catch is CancellationError { }
        catch { errorMessage = error.localizedDescription }
    }

    func canRespond(to invitation: HouseholdInvitationResponse, action: String, at date: Date = .now) -> Bool {
        guard activeInvitationId == nil else { return false }
        if let attempt = attempts[invitation.id] { return attempt.action == action }
        return invitation.isPending(at: date)
    }

    func respond(to invitation: HouseholdInvitationResponse, action: String) async {
        guard canRespond(to: invitation, action: action), ["accept", "decline", "revoke"].contains(action) else { return }
        let requestId = attempts[invitation.id]?.id ?? UUID()
        attempts[invitation.id] = (action, requestId)
        activeInvitationId = invitation.id
        errorMessage = nil
        defer { activeInvitationId = nil }
        do {
            switch action {
            case "accept": try await repository.accept(invitation, accountId: accountId, requestId: requestId)
            case "decline": try await repository.decline(invitation, accountId: accountId, requestId: requestId)
            default: try await repository.revoke(invitation, accountId: accountId, requestId: requestId)
            }
            attempts[invitation.id] = nil
        } catch is CancellationError { }
        catch {
            // A lost response may have followed a committed mutation. Only retry that same action.
            errorMessage = error.localizedDescription
        }
    }
}
