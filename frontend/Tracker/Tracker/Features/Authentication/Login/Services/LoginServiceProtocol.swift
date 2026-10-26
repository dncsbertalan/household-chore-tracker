nonisolated protocol LoginServiceProtocol: Sendable {
    func login(_ request: LoginRequest) async throws
}
