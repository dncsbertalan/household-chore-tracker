import SwiftUI

struct ProfileView: View {
    let isAuthenticated: Bool
    let isOnline: Bool
    let isLoggingOut: Bool
    let canLogOut: Bool
    let onLogout: () -> Void
    @AppStorage(AppLanguage.storageKey) private var language: AppLanguage = .system
    @State private var model: ProfileViewModel
    @State private var reload: Task<Void, Never>?

    init(
        service: any CurrentUserServiceProtocol,
        isAuthenticated: Bool,
        isOnline: Bool,
        isLoggingOut: Bool,
        canLogOut: Bool,
        onLogout: @escaping () -> Void
    ) {
        self.isAuthenticated = isAuthenticated
        self.isOnline = isOnline
        self.isLoggingOut = isLoggingOut
        self.canLogOut = canLogOut
        self.onLogout = onLogout
        _model = State(initialValue: ProfileViewModel(service: service))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                connectionStatus

                if !isAuthenticated {
                    ContentUnavailableView(
                        "profile.title", systemImage: "person.crop.circle",
                        description: Text("profile.signInPrompt")
                    )
                } else if model.isLoading {
                    ProgressView("profile.loading")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                } else if let user = model.user {
                    profileHeader(for: user)

                    LabeledContent("field.email") {
                        Text(user.email)
                            .textSelection(.enabled)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(20)
                    .background(.background, in: RoundedRectangle(cornerRadius: 20))
                }

                if isAuthenticated, let error = model.errorMessage {
                    VStack(spacing: 16) {
                        Text(error)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                        Button("profile.fetch") {
                            guard reload == nil else { return }
                            reload = Task {
                                await model.load()
                                reload = nil
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.isLoading)
                    }
                }

                LabeledContent("profile.language") {
                    Picker("profile.language", selection: $language) {
                        Text("profile.language.system").tag(AppLanguage.system)
                        Text(verbatim: "English").tag(AppLanguage.english)
                        Text(verbatim: "Magyar").tag(AppLanguage.hungarian)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .padding(20)
                .background(.background, in: RoundedRectangle(cornerRadius: 20))

                if isAuthenticated {
                    Button(role: .destructive, action: onLogout) {
                        HStack(spacing: 8) {
                            if isLoggingOut {
                                ProgressView()
                            }
                            Text("profile.logOut")
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                    .disabled(!canLogOut || isLoggingOut)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            if isAuthenticated { await model.load() }
        }
        .task(id: isAuthenticated) {
            if isAuthenticated { await model.load() }
        }
        .onDisappear {
            reload?.cancel()
            reload = nil
        }
    }

    private var connectionStatus: some View {
        let color: Color = isOnline ? .green : .red
        let title: LocalizedStringKey = isOnline
            ? "profile.connection.connected" : "profile.connection.notConnected"

        return Label(title, systemImage: isOnline ? "wifi" : "wifi.slash")
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.12), in: Capsule())
            .accessibilityIdentifier("profile.connectionStatus")
    }

    private func profileHeader(for user: CurrentUser) -> some View {
        var name = PersonNameComponents()
        name.givenName = user.firstName
        name.familyName = user.lastName
        let displayName = PersonNameComponentsFormatter.localizedString(from: name, style: .medium)
        let initials = [user.firstName, user.lastName]
            .compactMap { $0.split(whereSeparator: { $0.isWhitespace }).first?.prefix(1) }
            .joined()
            .uppercased()

        return VStack(spacing: 16) {
            Circle()
                .fill(LinearGradient(
                    colors: [Color(.systemGray3), Color(.systemGray)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: 104, height: 104)
                .overlay {
                    Text(initials)
                        .font(.system(size: 40, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(12)
                }
                .accessibilityHidden(true)

            Text(displayName)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

#if DEBUG
#Preview("Connected") {
    NavigationStack {
        ProfileView(
            service: CurrentUserPreviewService(), isAuthenticated: true,
            isOnline: true,
            isLoggingOut: false, canLogOut: true, onLogout: {}
        )
        .navigationTitle("profile.title")
    }
}

#Preview("Not connected") {
    NavigationStack {
        ProfileView(
            service: CurrentUserPreviewService(), isAuthenticated: true,
            isOnline: false,
            isLoggingOut: false, canLogOut: true, onLogout: {}
        )
        .navigationTitle("profile.title")
    }
}
#endif
