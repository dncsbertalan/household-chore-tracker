#if DEBUG
nonisolated struct LogoutPreviewService: LogoutServiceProtocol {
    func logout() async throws { }
}
#endif
