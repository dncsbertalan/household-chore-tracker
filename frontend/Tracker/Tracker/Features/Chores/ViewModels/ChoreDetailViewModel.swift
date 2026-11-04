import Foundation
import Observation

@MainActor
@Observable
final class ChoreDetailViewModel {
    private(set) var chore: ChoreResponse?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func load(id: UUID, accountId: UUID, store: HouseholdStore) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await store.chore(id: id, accountId: accountId)
            _ = try await store.household(id: response.householdId, accountId: accountId)
            try Task.checkCancellation()
            chore = response
        } catch is CancellationError { }
        catch { errorMessage = error.localizedDescription }
    }

    func didUpdate(_ response: ChoreResponse) { chore = response }
}
