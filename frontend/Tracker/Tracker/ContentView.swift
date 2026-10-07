import SwiftUI

struct ContentView: View {
    let registrationService: (any Registering)?
    let loginService: (any SigningIn)?
    let currentUserService: (any CurrentUserFetching)?
    let logoutService: (any SigningOut)?
    @State private var isShowingRegistration = false
    @State private var isShowingLogin = false
    @State private var isShowingProfile = false
    @State private var isLoggingOut = false
    @State private var logoutMessage: String?
    @State private var isShowingLogoutMessage = false

    var body: some View {
        NavigationStack {
            List {
                Button {
                    isShowingProfile = true
                } label: {
                    Label("profile.title", systemImage: "person.text.rectangle")
                }
                Button("auth.signOut", role: .destructive) {
                    guard let logoutService, !isLoggingOut else { return }
                    isLoggingOut = true
                    Task {
                        defer { isLoggingOut = false }
                        do {
                            try await logoutService.logout()
                            isShowingProfile = false
                            isShowingLogin = false
                            logoutMessage = String(localized: "auth.signedOut")
                        } catch {
                            logoutMessage = String(localized: "auth.signOutFailed", defaultValue: "Could not sign out: \(error.localizedDescription)")
                        }
                        isShowingLogoutMessage = true
                    }
                }
                .disabled(logoutService == nil || isLoggingOut)
            }
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
                LoginView(service: loginService)
            } else {
                ContentUnavailableView(
                    "configuration.required", systemImage: "network",
                    description: Text("configuration.instructions")
                )
            }
        }
        .sheet(isPresented: $isShowingProfile) {
            if let currentUserService {
                ProfileView(service: currentUserService)
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
    }

}

#if DEBUG
#Preview {
    ContentView(
        registrationService: RegistrationPreviewService(), loginService: LoginPreviewService(),
        currentUserService: CurrentUserPreviewService(), logoutService: LogoutPreviewService()
    )
}
#endif
