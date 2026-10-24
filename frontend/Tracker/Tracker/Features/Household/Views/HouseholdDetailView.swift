import SwiftUI
import SwiftData

struct HouseholdDetailView: View {
    let userId: UUID
    @Environment(HouseholdRouter.self) private var router
    @Query private var households: [LocalHousehold]

    init(householdId: UUID, userId: UUID) {
        self.userId = userId
        // Resolve stable route IDs against the current account's live local data.
        _households = Query(filter: #Predicate<LocalHousehold> {
            $0.householdId == householdId && $0.createdByUserId == userId && $0.deletedAt == nil
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
                        ForEach(household.householdRoles.filter { $0.deletedAt == nil }, id: \.householdRoleId) { role in
                            Text(role.name)
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
                    if household.hasPermission(.choreCreate, userId: userId) {
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
    }
}
