import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var sessionRevision = 0
    @Published var isAuthenticated = false

    func restoreAuthentication(from tokenStore: any TokenStoring) async {
        let revision = sessionRevision
        do {
            let tokens = try await tokenStore.load()
            // A startup read must not overwrite a login or logout that completed while it waited.
            guard revision == sessionRevision else { return }
            let now = Date()
            isAuthenticated = tokens.map {
                $0.refreshPending != true && ($0.accessExpiresAt > now || $0.refreshExpiresAt > now)
            } ?? false
        } catch {
            // An unavailable Keychain does not establish a session.
        }
    }
    
    enum Tab: Hashable {
        case home
        case search
        case cart
        case profile
    }
}
