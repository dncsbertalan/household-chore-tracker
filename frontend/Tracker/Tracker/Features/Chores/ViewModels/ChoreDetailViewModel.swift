import Foundation
import Observation

@MainActor
@Observable
final class ChoreDetailViewModel {
    private(set) var chore: ChoreResponse?
    private(set) var isLoading = false
    private(set) var isActing = false
    private(set) var actionError: String?
    private(set) var needsReload = false
    private(set) var successMessage: String?
    private(set) var successRevision = 0
    private var attempt: (action: ChoreAction, request: ChoreActionRequest, id: UUID)?
    private(set) var errorMessage: String?

    func load(id: UUID, accountId: UUID, store: HouseholdStore) async {
        guard !isLoading, !isActing else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await store.chore(id: id, accountId: accountId)
            _ = try await store.household(id: response.householdId, accountId: accountId)
            try Task.checkCancellation()
            chore = response
            attempt = nil
            actionError = nil
            needsReload = false
            successMessage = nil
        } catch is CancellationError { }
        catch { errorMessage = error.localizedDescription }
    }

    func canPerform(_ action: ChoreAction) -> Bool {
        guard !isActing, !isLoading, !needsReload, let chore, let actions = chore.actions else { return false }
        if let attempt, attempt.action != action { return false }
        switch action {
        case .start: return actions.canCreateOccurrence
        case .complete(let id): return actions.canComplete && chore.occurrence?.id == id
        case .approve(let id): return actions.canApprove && chore.pendingCompletion?.id == id
        case .reject(let id): return actions.canReject && chore.pendingCompletion?.id == id
        }
    }

    func perform(_ action: ChoreAction, accountId: UUID, store: HouseholdStore) async {
        guard canPerform(action), let chore else { return }
        let request = ChoreActionRequest(version: chore.version, occurrenceVersion: chore.occurrence?.version,
                                        completionVersion: chore.pendingCompletion?.version)
        if attempt?.action != action || attempt?.request != request { attempt = (action, request, UUID()) }
        guard let attempt else { return }
        isActing = true
        actionError = nil
        successMessage = nil
        defer { isActing = false }
        do {
            let response = try await store.perform(id: chore.id, accountId: accountId, action: action, request: request, requestId: attempt.id)
            self.chore = response
            self.attempt = nil
            switch action {
            case .start: successMessage = AppLocalization.string("chores.completion.started")
            case .complete(let id):
                if response.pendingCompletion != nil { successMessage = AppLocalization.string("chores.completion.submitted") }
                else if response.occurrence?.id != id { successMessage = AppLocalization.string("chores.completion.completedRecurring") }
                else { successMessage = AppLocalization.string("chores.completion.completed") }
            case .approve: successMessage = AppLocalization.string("chores.completion.approvalRecorded")
            case .reject: successMessage = AppLocalization.string("chores.completion.rejectionRecorded")
            }
            successRevision += 1
        } catch is CancellationError { }
        catch APIError.http(let status, _) where status == 409 {
            needsReload = true
            actionError = AppLocalization.string("chores.completion.conflict")
        } catch APIError.http(let status, _) where status == 403 {
            self.attempt = nil
            needsReload = true
            actionError = AppLocalization.string("chores.completion.permission")
        } catch { actionError = error.localizedDescription }
    }

    func didUpdate(_ response: ChoreResponse) {
        chore = response
        actionError = nil
        successMessage = nil
        needsReload = false
        attempt = nil
    }
}
