import SwiftUI
import SwiftData

struct RootView: View {
    let registrationService: (any Registering)?
    let loginService: (any SigningIn)?
    let currentUserService: (any CurrentUserFetching)?
    let logoutService: (any LogoutProtocol)?
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .system
    @State private var isShowingRegistration = false
    @State private var isShowingLogin = false
    @State private var isLoggingOut = false
    @State private var logoutMessage: String?
    @State private var isShowingLogoutMessage = false
    
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HouseholdCoordinatorView(currentUserService: currentUserService)
                .id(appState.sessionRevision)
                .tabItem { Label("household.tabName", systemImage: "house") }
                .tag(AppState.Tab.household)

            ChoresCoordinatorView(currentUserService: currentUserService)
                .id(appState.sessionRevision)
                .tabItem { Label("chores.title", systemImage: "checklist") }
                .tag(AppState.Tab.chores)
            
            NavigationStack {
                Group {
                    if let currentUserService {
                        ProfileView(
                            service: currentUserService,
                            isAuthenticated: appState.isAuthenticated,
                            isLoggingOut: isLoggingOut,
                            canLogOut: logoutService != nil,
                            onLogout: logout
                        )
                    } else {
                        ContentUnavailableView(
                            "configuration.required", systemImage: "network",
                            description: Text("configuration.instructions")
                        )
                    }
                }
                .navigationTitle("profile.title")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            isShowingLogin = true
                        } label: {
                            Label("auth.signIn", systemImage: "person.crop.circle")
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            isShowingRegistration = true
                        } label: {
                            Label("auth.register", systemImage: "person.badge.plus")
                        }
                    }
                }
            }
            .id(appState.sessionRevision)
            .tabItem { Label("profile.title", systemImage: "person") }
            .tag(AppState.Tab.profile)
        }
        // Recreate screen models so stored validation messages also use the new language.
        .id(language)
        .sheet(isPresented: $isShowingRegistration) {
            if let registrationService {
                RegistrationView(service: registrationService)
            } else {
                ContentUnavailableView(
                    "configuration.required",
                    systemImage: "network",
                    description: Text("configuration.instructions")
                )
            }
        }
        .sheet(isPresented: $isShowingLogin) {
            if let loginService {
                LoginView(service: loginService) {
                    appState.isAuthenticated = true
                    appState.sessionRevision += 1
                }
            } else {
                ContentUnavailableView(
                    "configuration.required", systemImage: "network",
                    description: Text("configuration.instructions")
                )
            }
        }
        .alert("auth.signOut", isPresented: $isShowingLogoutMessage) {
            Button("common.ok", role: .cancel) { }
        } message: {
            Text(logoutMessage ?? "")
        }
        .environment(\.locale, language.locale)
    }

    private func logout() {
        guard let logoutService, !isLoggingOut else { return }
        isLoggingOut = true
        Task {
            defer { isLoggingOut = false }
            do {
                try await logoutService.logout()
                appState.isAuthenticated = false
                appState.sessionRevision += 1
                isShowingLogin = false
                logoutMessage = AppLocalization.string("auth.signedOut")
            } catch {
                logoutMessage = AppLocalization.string("auth.signOutFailed", defaultValue: "Could not sign out: \(error.localizedDescription)")
            }
            isShowingLogoutMessage = true
        }
    }
}

#if DEBUG
#Preview {
    RootView(
        registrationService: RegistrationPreviewService(), loginService: LoginPreviewService(),
        currentUserService: CurrentUserPreviewService(), logoutService: LogoutPreviewService()
    )
    .environmentObject(AppState())
    .modelContainer(for: TrackerSchema.models,
                    inMemory: true)
}
#endif
