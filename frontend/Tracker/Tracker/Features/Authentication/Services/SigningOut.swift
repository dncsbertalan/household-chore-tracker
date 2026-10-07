import Foundation

nonisolated protocol SigningOut: Sendable {
    func logout() async throws
}

#if DEBUG
nonisolated struct LogoutPreviewService: SigningOut {
    func logout() async throws { }
}
#endif
