import SwiftUI
import SwiftData

struct HouseholdDetailView: View {
    @Query private var households: [LocalHousehold]

    init(householdId: UUID, userId: UUID) {
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
                }
                .navigationTitle(household.name)
            } else {
                ContentUnavailableView("household.unavailable", systemImage: "house",
                                       description: Text("household.unavailableHelp"))
                    .navigationTitle("household.details")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
