import Foundation

enum HouseholdSheet: Hashable, Identifiable {
    case createHousehold
    case createChore(householdId: UUID)
    case sendInvitation(householdId: UUID)

    var id: Self { self }
}
