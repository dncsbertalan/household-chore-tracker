import Foundation

/// Uses the current server representation to control UI actions. The backend enforces authorization.
@MainActor
struct HouseholdAuthorizationService {
    func hasPermission(_ permission: HouseholdPermission, in household: Household, userId: UUID) -> Bool {
        household.members.contains { $0.userInfo.userId == userId && $0.householdId == household.householdId
            && $0.householdRole.householdId == household.householdId
            && $0.householdRole.permissions.contains { $0.name == permission } }
    }
}
