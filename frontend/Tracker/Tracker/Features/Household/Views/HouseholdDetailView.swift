import SwiftUI

struct HouseholdDetailView: View {
    let userId: UUID
    let invitationRepository: HouseholdInvitationRepository?
    private let authorization = HouseholdAuthorizationService()
    @Environment(HouseholdRouter.self) private var router
    let householdId: UUID
    @Environment(HouseholdStore.self) private var store
    @State private var isLoading = false
    @State private var errorMessage: String?
    private var householdChores: [ChoreResponse] { store.chores.filter { $0.householdId == householdId } }


    init(householdId: UUID, userId: UUID, invitationRepository: HouseholdInvitationRepository? = nil) {
        self.userId = userId
        self.invitationRepository = invitationRepository
        self.householdId = householdId
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("household.details", systemImage: "house")
                } description: { Text(errorMessage) } actions: {
                    Button("household.retry") { Task { await refresh() } }
                }
            } else if let household = store.household(id: householdId) {
                List {
                    Section("household.details") {
                        LabeledContent("household.name", value: household.name)
                        if let description = household.description, !description.isEmpty {
                            Text(description)
                        }
                    }
                    Section("household.roles") {
                        ForEach(household.roles.filter { role in
                            authorization.hasPermission(.roleView, in: household, userId: userId)
                                || authorization.hasPermission(.memberInvite, in: household, userId: userId)
                                || household.members.contains { $0.userId == userId && $0.householdRole.householdRoleId == role.householdRoleId }
                        }, id: \.householdRoleId) { role in
                            Text(role.name)
                        }
                    }
                    if authorization.hasPermission(.memberInvite, in: household, userId: userId) {
                        Section {
                            Button {
                                router.sheet = .sendInvitation(householdId: household.householdId)
                            } label: {
                                Label("invitation.send.title", systemImage: "person.badge.plus")
                            }
                            .disabled(invitationRepository == nil)
                            .accessibilityIdentifier("inviteHouseholdMember")
                            if let invitationRepository {
                                NavigationLink {
                                    HouseholdInvitationsView(accountId: userId, householdId: household.householdId,
                                                             repository: invitationRepository)
                                } label: {
                                    Label("invitation.list.sent", systemImage: "envelope")
                                }
                            }
                        }
                    }
                    if !householdChores.isEmpty {
                        Section("chores.title") {
                            ForEach(householdChores, id: \.choreId) { chore in
                                NavigationLink(value: HouseholdRoute.choreDetail(choreId: chore.id)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(chore.title).font(.headline)
                                        if let description = chore.description {
                                            Text(description).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .accessibilityIdentifier("chore-\(chore.id.uuidString)")
                            }
                        }
                    }
                }
                .navigationTitle(household.name)
                .toolbar {
                    if authorization.hasPermission(.choreCreate, in: household, userId: userId) {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                router.sheet = .createChore(householdId: household.householdId)
                            } label: {
                                Label("chores.create", systemImage: "plus")
                            }
                            .accessibilityIdentifier("addChore")
                        }
                    }
                }
            } else {
                ContentUnavailableView("household.unavailable", systemImage: "house",
                                       description: Text("household.unavailableHelp"))
                    .navigationTitle("household.details")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await refresh() }
        .refreshable { await refresh() }
    }

    private func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await store.household(id: householdId, accountId: userId)
            _ = try await store.chores(accountId: userId, householdId: householdId)
        } catch is CancellationError { }
        catch { errorMessage = error.localizedDescription }
    }
}
