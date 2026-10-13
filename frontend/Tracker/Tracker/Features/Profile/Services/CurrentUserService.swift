import Foundation

nonisolated protocol CurrentUserFetching: Sendable {
    func fetchCurrentUser() async throws -> CurrentUser
}

nonisolated struct CurrentUserService: CurrentUserFetching {
    private let client: any APIRequesting

    init(client: any APIRequesting) { self.client = client }

    func fetchCurrentUser() async throws -> CurrentUser {
        try await client.request(endpoint: "users/me", retryPolicy: .transientReads, as: CurrentUser.self)
    }
}

#if DEBUG
nonisolated struct CurrentUserPreviewService: CurrentUserFetching {
    func fetchCurrentUser() async throws -> CurrentUser {
        CurrentUser(id: UUID(), email: "alex@example.com", firstName: "Alex", lastName: "Example")
    }
}
#endif
