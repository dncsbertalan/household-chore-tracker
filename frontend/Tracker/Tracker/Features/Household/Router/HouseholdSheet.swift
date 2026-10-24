import Foundation

enum HouseholdSheet: Hashable, Identifiable {
    case createHousehold
    case createChore(householdId: UUID)

    var id: Self { self }
}
