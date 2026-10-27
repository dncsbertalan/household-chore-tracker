import Foundation

/// Evaluates local household grants for UI and offline operations.
@MainActor
struct HouseholdAuthorizationService {
    func hasPermission(
        _ permission: HouseholdPermission,
        in household: LocalHousehold,
        userId: UUID
    ) -> Bool {
        authorizedMember(permission, in: household, userId: userId) != nil
    }

    /// Use the current session's user ID and check again immediately before saving a protected operation.
    @discardableResult
    func requirePermission(
        _ permission: HouseholdPermission,
        in household: LocalHousehold,
        userId: UUID
    ) throws -> LocalHouseholdMember {
        guard let member = authorizedMember(permission, in: household, userId: userId) else {
            throw HouseholdAuthorizationError.permissionDenied(permission)
        }
        return member
    }

    private func authorizedMember(
        _ permission: HouseholdPermission, in household: LocalHousehold, userId: UUID
    ) -> LocalHouseholdMember? {
        guard household.deletedAt == nil else { return nil }
        return household.householdMembers.first { member in
            member.userId == userId && member.deletedAt == nil
                && member.household.householdId == household.householdId
                && member.role.deletedAt == nil
                && member.role.household.householdId == household.householdId
                && member.role.permissions.contains(permission)
        }
    }
}
