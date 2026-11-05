import Foundation

enum HouseholdRoute: Hashable {
    case roles(householdId: UUID)
    case detail(householdId: UUID)
    case choreDetail(choreId: UUID)
}
