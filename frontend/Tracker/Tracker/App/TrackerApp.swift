import OSLog
import SwiftData
import SwiftUI

@main
struct TrackerApp: App {
    @StateObject private var appState = AppState()

    private let registrationService: RegistrationService?
    private let loginService: LoginService?
    private let currentUserService: CurrentUserService?
    private let tokenStore: KeychainTokenStore?
    private let syncEngine: SyncEngine?
    private let connectivityMonitor = NetworkConnectivityMonitor()
    @Environment(\.scenePhase) private var scenePhase
    private let container = AppModelContainer()

    init() {
        if let configuration = try? APIConfiguration.from() {
            let client = APIClient(configuration: configuration)
            registrationService = RegistrationService(client: client)
            let tokenStore = KeychainTokenStore(
                service:
                    "\(Bundle.main.bundleIdentifier ?? "hu.dncs.Tracker").auth.\(configuration.baseURL.absoluteString)"
            )
            self.tokenStore = tokenStore
            loginService = LoginService(client: client, tokenStore: tokenStore)
            let session = TokenRefreshService(
                client: client,
                tokenStore: tokenStore
            )
            let authenticatedClient = AuthenticatedAPIClient(
                client: client,
                session: session
            )
            let userService = CurrentUserService(
                client: authenticatedClient
            )
            currentUserService = userService
            syncEngine = SyncEngine(
                queue: OutboxQueue(container: container),
                dispatcher: OutboxDispatcher(handlers: [
                    CreateHouseholdOutboxHandler(client: authenticatedClient)
                ]),
                currentUserService: userService
            )
        } else {
            registrationService = nil
            loginService = nil
            currentUserService = nil
            tokenStore = nil
            syncEngine = nil
        }
    }

    private func updateSync() {
        if appState.isAuthenticated && scenePhase == .active {
            syncEngine?.start()
        } else {
            syncEngine?.stop()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                registrationService: registrationService,
                loginService: loginService,
                currentUserService: currentUserService,
                logoutService: loginService
            )
            .environmentObject(appState)
            .task {
                if let tokenStore {
                    await appState.restoreAuthentication(from: tokenStore)
                }
                updateSync()
                connectivityMonitor.start { connected in
                    if connected { syncEngine?.requestSync() }
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: .outboxDidEnqueue)
            ) { _ in
                syncEngine?.requestSync()
            }
            .onChange(of: scenePhase) { _, _ in updateSync() }
            .onChange(of: appState.isAuthenticated) { _, _ in updateSync() }
            .onChange(of: appState.sessionRevision) { _, _ in
                syncEngine?.stop()
                updateSync()
            }
        }
        .modelContainer(container.modelContainer)
    }
}
