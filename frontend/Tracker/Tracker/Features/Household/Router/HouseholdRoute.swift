import Foundation

enum HouseholdRoute: Hashable {
    case detail(householdId: UUID)
    case choreDetail(choreId: UUID)
}
