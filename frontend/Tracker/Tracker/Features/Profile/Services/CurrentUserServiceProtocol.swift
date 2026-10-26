nonisolated protocol CurrentUserServiceProtocol: Sendable {
    func fetchCurrentUser() async throws -> CurrentUser
}
