nonisolated enum HouseholdAuthorizationError: Error, Equatable {
    case permissionDenied(HouseholdPermission)
}
