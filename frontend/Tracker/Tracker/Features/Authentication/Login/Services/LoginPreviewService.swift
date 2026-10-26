#if DEBUG
nonisolated struct LoginPreviewService: LoginServiceProtocol {
    func login(_ request: LoginRequest) async throws { }
}
#endif
