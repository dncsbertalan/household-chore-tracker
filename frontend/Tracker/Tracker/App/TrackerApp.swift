import SwiftUI

@main
struct TrackerApp: App {
    @StateObject private var appState: AppState
    @State private var store: HouseholdStore
    private let registrationService: (any RegistrationServiceProtocol)?
    private let loginService: (any LoginServiceProtocol)?
    private let logoutService: (any LogoutServiceProtocol)?
    private let currentUserService: (any CurrentUserServiceProtocol)?
    private let invitationRepository: HouseholdInvitationRepository?
    private let tokenStore: KeychainTokenStore?
    private let connectivityMonitor = NetworkConnectivityMonitor()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)
        #if DEBUG
        if ChoreUITestFixture.isEnabled {
            let repository = ChoreUITestRepository()
            _store = State(initialValue: HouseholdStore(households: repository, chores: repository))
            state.isAuthenticated = true
            state.isOnline = true
            registrationService = nil
            loginService = nil
            logoutService = nil
            currentUserService = ChoreUITestUserService()
            tokenStore = nil
            invitationRepository = nil
            return
        }
        if InvitationUITestFixture.isEnabled {
            let store = HouseholdStore(households: InvitationUITestHouseholdRepository(), chores: InvitationUITestHouseholdRepository())
            _store = State(initialValue: store)
            state.isAuthenticated = true
            state.isOnline = true
            registrationService = nil
            loginService = nil
            logoutService = nil
            currentUserService = InvitationUITestUserService()
            tokenStore = nil
            invitationRepository = HouseholdInvitationRepository(service: InvitationUITestService(), store: store)
            return
        }
        #endif
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
            invitationRepository = nil
            tokenStore = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(registrationService: registrationService, loginService: loginService,
                     currentUserService: currentUserService, logoutService: logoutService,
                     invitationRepository: invitationRepository)
            .environmentObject(appState)
            .environment(store)
            .task {
                #if DEBUG
                if InvitationUITestFixture.isEnabled || ChoreUITestFixture.isEnabled { return }
                #endif
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
