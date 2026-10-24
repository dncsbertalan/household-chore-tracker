import Foundation

nonisolated protocol LogoutProtocol: Sendable {
    func logout() async throws
}

#if DEBUG
nonisolated struct LogoutPreviewService: LogoutProtocol {
    func logout() async throws { }
}
#endif
