import Foundation

nonisolated protocol CurrentUserFetching: Sendable {
    func fetchCurrentUser() async throws -> CurrentUser
}

nonisolated struct CurrentUserService: CurrentUserFetching {
    private let client: AuthenticatedAPIClient

    init(client: AuthenticatedAPIClient) { self.client = client }

    func fetchCurrentUser() async throws -> CurrentUser {
        try await client.send(APIEndpoint(path: "users/me"), as: CurrentUser.self)
    }
}

#if DEBUG
nonisolated struct CurrentUserPreviewService: CurrentUserFetching {
    func fetchCurrentUser() async throws -> CurrentUser {
        CurrentUser(id: UUID(), email: "alex@example.com", firstName: "Alex", lastName: "Example")
    }
}
#endif
