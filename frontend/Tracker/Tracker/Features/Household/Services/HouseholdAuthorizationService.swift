import Foundation

/// Evaluates local household grants for UI and offline operations.
@MainActor
struct HouseholdAuthorizationService {
    func hasPermission(
        _ permission: HouseholdPermission,
        in household: LocalHousehold,
        userId: UUID
    ) -> Bool {
        household.deletedAt == nil
            && household.householdMembers.contains { member in
                member.userId == userId
                    && member.deletedAt == nil
                    && member.household.householdId == household.householdId
                    && member.role.deletedAt == nil
                    && member.role.household.householdId
                        == household.householdId
                    && member.role.permissions.contains(permission)
            }
    }

    /// Use the current session's user ID and check again immediately before saving a protected operation.
    func requirePermission(
        _ permission: HouseholdPermission,
        in household: LocalHousehold,
        userId: UUID
    ) throws {
        guard hasPermission(permission, in: household, userId: userId) else {
            throw HouseholdAuthorizationError.permissionDenied(permission)
        }
    }
}
