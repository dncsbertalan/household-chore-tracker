import SwiftUI

struct HouseholdListView: View {
    let currentUserService: (any CurrentUserServiceProtocol)?
    let model: CurrentUserViewModel
    let invitationRepository: HouseholdInvitationRepository?
    @Environment(HouseholdRouter.self) private var router
    @Environment(HouseholdStore.self) private var store
    @State private var isLoading = false
    @State private var errorMessage: String?
    private var households: [Household] { store.households }


    init(currentUserService: (any CurrentUserServiceProtocol)? = nil, model: CurrentUserViewModel, invitationRepository: HouseholdInvitationRepository? = nil) {
        self.currentUserService = currentUserService
        self.model = model
        self.invitationRepository = invitationRepository

    }

    var body: some View {
        Group {
            if model.userId != nil {
                if isLoading {
                    ProgressView()
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label("household.title", systemImage: "house")
                    } description: { Text(errorMessage) } actions: {
                        Button("household.retry") { Task { await refresh() } }
                    }
                } else {
                    householdList
                }
            } else if model.isLoading {
                ProgressView()
            } else {
                ContentUnavailableView {
                    Label("household.title", systemImage: "house")
                } description: {
                    Text(model.errorMessage ?? AppLocalization.string("household.error.currentUser"))
                } actions: {
                    Button("household.retry") {
                        Task { await model.loadUser(service: currentUserService) }
                    }
                }
            }
        }
        .navigationTitle("household.title")
        .toolbar {
            if let userId = model.userId, let invitationRepository {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        HouseholdInvitationsView(accountId: userId, repository: invitationRepository)
                    } label: {
                        Label("invitation.list.inbox", systemImage: "tray")
                    }
                    .accessibilityIdentifier("invitationInbox")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.sheet = .createHousehold
                } label: {
                    Label("household.create", systemImage: "plus")
                }
                .disabled(model.userId == nil)
                .accessibilityIdentifier("addHousehold")
            }
        }
        .task { await model.loadUser(service: currentUserService) }
        .task(id: model.userId) { await refresh() }
        .refreshable { await refresh() }
    }

    private func refresh() async {
        guard let userId = model.userId, !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do { _ = try await store.households(accountId: userId) }
        catch is CancellationError { }
        catch { errorMessage = error.localizedDescription }
    }

    @ViewBuilder
    private var householdList: some View {
        if households.isEmpty {
            List {
                ContentUnavailableView("household.empty", systemImage: "house",
                                       description: Text("household.emptyHelp"))
                    .listRowBackground(Color.clear)
            }
        } else {
            List(households) { household in
                NavigationLink(value: HouseholdRoute.detail(householdId: household.householdId)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(household.name).font(.headline)
                        if let description = household.description, !description.isEmpty {
                            Text(description).foregroundStyle(.secondary)
                        }
                    }
                }
                .accessibilityIdentifier("household-\(household.householdId.uuidString)")
            }
        }
    }
}

#if DEBUG
#Preview {
    HouseholdCoordinatorView(currentUserService: CurrentUserPreviewService())
        .environmentObject(AppState())
        .environment(HouseholdStore())
}
#endif
