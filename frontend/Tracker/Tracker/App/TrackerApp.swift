import SwiftUI
import SwiftData
import OSLog

@main
struct TrackerApp: App {
    @StateObject private var appState = AppState()
    
    private let registrationService: RegistrationService?
    private let loginService: LoginService?
    private let currentUserService: CurrentUserService?
    private let tokenStore: KeychainTokenStore?
    private let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: TrackerSchema.schema)
        } catch {
            fatalError("Could not open the app's SwiftData store: \(error)")
        }
        
        if let configuration = try? APIConfiguration.from() {
            let client = APIClient(configuration: configuration)
            registrationService = RegistrationService(client: client)
            let tokenStore = KeychainTokenStore(
                service: "\(Bundle.main.bundleIdentifier ?? "hu.dncs.Tracker").auth.\(configuration.baseURL.absoluteString)"
            )
            self.tokenStore = tokenStore
            loginService = LoginService(client: client, tokenStore: tokenStore)
            let session = TokenRefreshService(client: client, tokenStore: tokenStore)
            let authenticatedClient = AuthenticatedAPIClient(client: client, session: session)
            let userService = CurrentUserService(
                client: authenticatedClient
            )
            currentUserService = userService
        } else {
            registrationService = nil
            loginService = nil
            currentUserService = nil
            tokenStore = nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(
                registrationService: registrationService, loginService: loginService,
                currentUserService: currentUserService, logoutService: loginService
            )
            .environmentObject(appState)
            .task {
                if let tokenStore {
                    await appState.restoreAuthentication(from: tokenStore)
                }
            }
        }
        .modelContainer(container)
    }
}
