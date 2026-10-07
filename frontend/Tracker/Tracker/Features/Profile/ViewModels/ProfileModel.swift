import Foundation
import Observation

@MainActor
@Observable
final class ProfileModel {
    private(set) var user: CurrentUser?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private let service: any CurrentUserFetching

    init(service: any CurrentUserFetching) { self.service = service }

    func load() async {
        guard !isLoading else { return }
        user = nil
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await service.fetchCurrentUser()
            try Task.checkCancellation()
            self.user = user
        } catch is CancellationError {
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
