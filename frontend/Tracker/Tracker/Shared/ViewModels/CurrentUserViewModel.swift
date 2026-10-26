import Foundation
import Observation

@Observable
@MainActor
final class CurrentUserViewModel {
    private(set) var userId: UUID?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func loadUser(service: (any CurrentUserServiceProtocol)?) async {
        guard !isLoading, userId == nil else { return }
        guard let service else {
            errorMessage = AppLocalization.string("configuration.required")
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
            errorMessage = AppLocalization.string("household.error.currentUser")
        }
    }
}
