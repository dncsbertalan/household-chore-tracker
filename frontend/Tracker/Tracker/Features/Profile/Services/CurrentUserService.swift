import Foundation

nonisolated struct CurrentUserService: CurrentUserServiceProtocol {
    private let client: any APIClientProtocol

    init(client: any APIClientProtocol) { self.client = client }

    func fetchCurrentUser() async throws -> CurrentUser {
        try await client.request(endpoint: "users/me", retryPolicy: .transientReads, as: CurrentUser.self)
    }
}
