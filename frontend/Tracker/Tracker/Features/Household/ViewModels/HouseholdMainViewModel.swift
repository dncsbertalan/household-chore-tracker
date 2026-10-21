import Foundation
import Observation

@Observable
@MainActor
final class HouseholdMainViewModel {
    private(set) var userId: UUID?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func loadUser(service: (any CurrentUserFetching)?) async {
        guard !isLoading, userId == nil else { return }
        guard let service else {
            errorMessage = String(localized: "configuration.required")
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let user = try await service.fetchCurrentUser()
            try Task.checkCancellation()
            userId = user.id
        } catch is CancellationError {
        } catch {
            errorMessage = String(localized: "household.error.currentUser")
        }
    }
}
