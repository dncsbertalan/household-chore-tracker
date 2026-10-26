import Foundation

nonisolated protocol LogoutServiceProtocol: Sendable {
    func logout() async throws
}
