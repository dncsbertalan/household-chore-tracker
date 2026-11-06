import SwiftUI

@main
struct TrackerApp: App {
    @StateObject private var appState: AppState
    @State private var store: HouseholdStore
    private let registrationService: (any RegistrationServiceProtocol)?
    private let loginService: (any LoginServiceProtocol)?
    private let logoutService: (any LogoutServiceProtocol)?
    private let currentUserService: (any CurrentUserServiceProtocol)?
    private let roleRepository: OfflineFirstHouseholdRoleRepository?
    private let invitationRepository: HouseholdInvitationRepository?
    private let tokenStore: KeychainTokenStore?
    private let connectivityMonitor = NetworkConnectivityMonitor()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)

        if let configuration = try? APIConfiguration.from() {
            let client = APIClient(configuration: configuration)
            registrationService = RegistrationService(client: client)
            let tokens = KeychainTokenStore(service:
                                                "\(Bundle.main.bundleIdentifier ?? "hu.dncs.Tracker").auth.\(configuration.baseURL.absoluteString)")
            tokenStore = tokens
            let login = LoginService(client: client, tokenStore: tokens)
            loginService = login
            logoutService = login
            let session = TokenRefreshService(client: client, tokenStore: tokens)
            let authenticatedClient = AuthenticatedAPIClient(client: client, session: session)
            currentUserService = CurrentUserService(client: authenticatedClient)
            roleRepository = OfflineFirstHouseholdRoleRepository(
                remote: RemoteHouseholdRoleRepository(client: authenticatedClient),
                local: FileHouseholdRoleStore(namespace: configuration.baseURL.absoluteString))
            let store = HouseholdStore(households: RemoteHouseholdRepository(client: authenticatedClient),
                                       chores: RemoteChoreRepository(client: authenticatedClient))
            _store = State(initialValue: store)
            invitationRepository = HouseholdInvitationRepository(
                service: HouseholdInvitationService(client: authenticatedClient), store: store)
        } else {
            _store = State(initialValue: HouseholdStore())
            registrationService = nil
            loginService = nil
            logoutService = nil
            currentUserService = nil
            roleRepository = nil
            invitationRepository = nil
            tokenStore = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(registrationService: registrationService, loginService: loginService,
                     currentUserService: currentUserService, logoutService: logoutService,
                     invitationRepository: invitationRepository, roleRepository: roleRepository)
            .environmentObject(appState)
            .environment(store)
            .onChange(of: appState.sessionRevision) { _, _ in
                roleRepository?.invalidateSession()
            }
            .task {
                // Connectivity is informational; failed requests use the normal API error path.
                connectivityMonitor.start { appState.isOnline = $0 }
                if let tokenStore { await appState.restoreAuthentication(from: tokenStore) }
            }
            .task(id: "\(scenePhase == .active)-\(appState.isAuthenticated)-\(appState.sessionRevision)") {
                guard scenePhase == .active, appState.isAuthenticated,
                      let currentUserService, let invitationRepository else { return }
                do {
                    let user = try await currentUserService.fetchCurrentUser()
                    try Task.checkCancellation()
                    await invitationRepository.refreshOnForeground(accountId: user.id)
                } catch { /* Visible screens expose request errors and explicit retry. */ }
            }

        }
    }
}
