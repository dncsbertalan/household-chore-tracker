import SwiftUI
import SwiftData

struct HouseholdListView: View {
    @Query private var households: [LocalHousehold]

    init(userId: UUID) {
        _households = Query(filter: #Predicate<LocalHousehold> {
            $0.createdByUserId == userId && $0.deletedAt == nil
        })
    }

    var body: some View {
        if households.isEmpty {
            ContentUnavailableView("household.empty", systemImage: "house",
                                   description: Text("household.emptyHelp"))
        } else {
            List(households) { household in
                NavigationLink(value: HouseholdRoute.detail(householdId: household.householdId)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(household.name).font(.headline)
                        if let description = household.householdDescription, !description.isEmpty {
                            Text(description).foregroundStyle(.secondary)
                        }
                    }
                }
                .accessibilityIdentifier("household-\(household.householdId.uuidString)")
            }
        }
    }
}
