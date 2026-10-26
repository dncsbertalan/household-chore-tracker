import Foundation

#if DEBUG
nonisolated struct CurrentUserPreviewService: CurrentUserServiceProtocol {
    func fetchCurrentUser() async throws -> CurrentUser {
        CurrentUser(id: UUID(), email: "alex@example.com", firstName: "Alex", lastName: "Example")
    }
}
#endif
