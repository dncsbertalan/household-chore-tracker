import SwiftUI
import SwiftData

struct HouseholdDetailView: View {
    let userId: UUID
    private let authorization = HouseholdAuthorizationService()
    @Environment(HouseholdRouter.self) private var router
    @Query private var households: [LocalHousehold]

    init(householdId: UUID, userId: UUID) {
        self.userId = userId
        // Resolve stable route IDs against the current account's live local data.
        _households = Query(filter: #Predicate<LocalHousehold> {
            $0.householdId == householdId && $0.deletedAt == nil
                && $0.householdMembers.contains { member in
                    member.userId == userId && member.deletedAt == nil && member.role.deletedAt == nil
                }
        })
    }

    var body: some View {
        Group {
            if let household = households.first {
                List {
                    Section("household.details") {
                        LabeledContent("household.name", value: household.name)
                        if let description = household.householdDescription, !description.isEmpty {
                            Text(description)
                        }
                    }
                    Section("household.roles") {
                        ForEach(household.householdRoles.filter { role in
                            role.deletedAt == nil && (authorization.hasPermission(.roleView, in: household, userId: userId)
                                || authorization.hasPermission(.memberInvite, in: household, userId: userId)
                                || household.householdMembers.contains { $0.userId == userId && $0.deletedAt == nil
                                    && $0.role.householdRoleId == role.householdRoleId })
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
                            .accessibilityIdentifier("inviteHouseholdMember")
                        }
                    }
                    if !household.chores.filter({ $0.deletedAt == nil }).isEmpty {
                        Section("chores.title") {
                            ForEach(household.chores.filter { $0.deletedAt == nil }, id: \.choreId) { chore in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(chore.title).font(.headline)
                                    if let description = chore.choreDescription {
                                        Text(description).foregroundStyle(.secondary)
                                    }
                                }
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
        .refreshable { await syncEngine?.refresh() }
    }
}
