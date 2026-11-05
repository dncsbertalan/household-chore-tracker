import Foundation

@MainActor
struct HouseholdRoleError {
    let message: String
    let needsReload: Bool
    init(_ error: Error) {
        needsReload = switch error {
        case APIError.http(let status, let problem): status == 403 || status == 404 || problem?.code == "household_role_stale" || problem?.code == "household_role_system_role"
        default: false
        }
        switch error {
        case APIError.http(let status, _) where status == 403:
            message = AppLocalization.string("roles.error.permission")
        case APIError.http(_, let problem) where problem?.code == "household_role_duplicate_name":
            message = AppLocalization.string("roles.error.duplicate")
        case APIError.http(_, let problem) where problem?.code == "household_role_last_manager":
            message = AppLocalization.string("roles.error.lastManager")
        case APIError.http(_, let problem) where problem?.code == "household_role_in_use":
            message = AppLocalization.string("roles.error.inUse")
        case APIError.http(_, let problem) where problem?.code == "household_role_system_role":
            message = AppLocalization.string("roles.systemRole")
        case APIError.http(let status, _) where status == 409 || status == 404:
            message = AppLocalization.string("roles.error.stale")
        default: message = error.localizedDescription
        }
    }
}
