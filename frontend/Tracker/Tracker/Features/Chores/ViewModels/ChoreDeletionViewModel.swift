import Foundation
import Observation

@MainActor
@Observable
final class ChoreDeletionViewModel {
    var isShowingConfirmation = false
    private(set) var pendingChore: ChoreResponse?
    private(set) var isDeleting = false
    private(set) var didDelete = false
    private(set) var errorMessage: String?
    private(set) var needsReload = false
    private var attempt: (id: UUID, version: Int64, key: UUID)?

    func requestConfirmation(for chore: ChoreResponse, household: Household, accountId: UUID) {
        guard !isDeleting, !didDelete, !needsReload, chore.householdId == household.id,
              HouseholdAuthorizationService().hasPermission(.choreDelete, in: household, userId: accountId) else { return }
        pendingChore = chore
        isShowingConfirmation = true
    }
    func cancelConfirmation() { isShowingConfirmation = false; pendingChore = nil }
    func didReload() { needsReload = false; errorMessage = nil; cancelConfirmation() }

    func confirmDeletion(accountId: UUID, using store: HouseholdStore) async {
        guard let chore = pendingChore, !isDeleting, !didDelete, !needsReload else { return }
        guard let current = store.chore(id: chore.id), current.householdId == chore.householdId,
              let household = store.household(id: current.householdId),
              HouseholdAuthorizationService().hasPermission(.choreDelete, in: household, userId: accountId) else {
            cancelConfirmation()
            errorMessage = AppLocalization.string("chores.delete.error.permission")
            needsReload = true
            return
        }
        isShowingConfirmation = false
        if attempt?.id != chore.id || attempt?.version != chore.version { attempt = (chore.id, chore.version, UUID()) }
        guard let attempt else { return }
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false; pendingChore = nil }
        do {
            try await store.deleteChore(id: chore.id, version: chore.version, accountId: accountId, requestId: attempt.key)
            didDelete = true
        } catch is CancellationError { }
        catch {
            if case APIError.http(let status, _) = error {
                needsReload = [403, 404, 409, 410].contains(status)
                if status == 403 { errorMessage = AppLocalization.string("chores.delete.error.permission") }
                else if [404, 409, 410].contains(status) { errorMessage = AppLocalization.string("chores.delete.error.changed") }
                else { errorMessage = error.localizedDescription }
            } else { errorMessage = error.localizedDescription }
        }
    }
}
