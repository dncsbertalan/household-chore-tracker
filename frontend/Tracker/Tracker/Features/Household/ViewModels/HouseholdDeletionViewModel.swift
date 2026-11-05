import Foundation
import Observation

@MainActor
@Observable
final class HouseholdDeletionViewModel {
    var isShowingConfirmation = false
    private(set) var pendingHousehold: HouseholdResponse?
    private(set) var isDeleting = false
    private(set) var didDelete = false
    private(set) var errorMessage: String?
    private(set) var needsReload = false
    private var attempt: (id: UUID, version: Int64, key: UUID)?

    func requestConfirmation(for household: HouseholdResponse, accountId: UUID) {
        guard !isDeleting, !didDelete, !needsReload,
              HouseholdAuthorizationService().hasPermission(.delete, in: household, userId: accountId) else { return }
        pendingHousehold = household
        isShowingConfirmation = true
    }
    func cancelConfirmation() { isShowingConfirmation = false; pendingHousehold = nil }
    func didReload() { needsReload = false; errorMessage = nil; cancelConfirmation() }

    func confirmDeletion(accountId: UUID, using store: HouseholdStore) async {
        guard let household = pendingHousehold, !isDeleting, !didDelete, !needsReload else { return }
        guard let current = store.household(id: household.id),
              HouseholdAuthorizationService().hasPermission(.delete, in: current, userId: accountId) else {
            cancelConfirmation()
            errorMessage = AppLocalization.string("household.delete.error.permission")
            needsReload = true
            return
        }
        isShowingConfirmation = false
        if attempt?.id != household.id || attempt?.version != household.version {
            attempt = (household.id, household.version, UUID())
        }
        guard let attempt else { return }
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false; pendingHousehold = nil }
        do {
            try await store.deleteHousehold(id: household.id, version: household.version, accountId: accountId, requestId: attempt.key)
            didDelete = true
        } catch is CancellationError { }
        catch {
            if case APIError.http(let status, let problem) = error {
                needsReload = [403, 404, 409, 410].contains(status)
                if status == 403 { errorMessage = AppLocalization.string("household.delete.error.permission") }
                else if problem?.code == "household_delete_stale" || [404, 409, 410].contains(status) {
                    errorMessage = AppLocalization.string("household.delete.error.changed")
                } else { errorMessage = error.localizedDescription }
            } else { errorMessage = error.localizedDescription }
        }
    }
}
