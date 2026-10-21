import Foundation

/// Stable names from the backend's HouseholdPermission catalog; server IDs are not local IDs.
nonisolated enum HouseholdPermission: String, Codable, CaseIterable, Identifiable, Sendable {
    case view = "HOUSEHOLD_VIEW"
    case update = "HOUSEHOLD_UPDATE"
    case delete = "HOUSEHOLD_DELETE"
    case memberView = "HOUSEHOLD_MEMBER_VIEW"
    case memberInvite = "HOUSEHOLD_MEMBER_INVITE"
    case memberRemove = "HOUSEHOLD_MEMBER_REMOVE"
    case memberAssignRole = "HOUSEHOLD_MEMBER_ASSIGN_ROLE"
    case roleView = "HOUSEHOLD_ROLE_VIEW"
    case roleCreate = "HOUSEHOLD_ROLE_CREATE"
    case roleUpdate = "HOUSEHOLD_ROLE_UPDATE"
    case roleDelete = "HOUSEHOLD_ROLE_DELETE"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .view: String(localized: "household.permission.view")
        case .update: String(localized: "household.permission.update")
        case .delete: String(localized: "household.permission.delete")
        case .memberView: String(localized: "household.permission.memberView")
        case .memberInvite: String(localized: "household.permission.memberInvite")
        case .memberRemove: String(localized: "household.permission.memberRemove")
        case .memberAssignRole: String(localized: "household.permission.memberAssignRole")
        case .roleView: String(localized: "household.permission.roleView")
        case .roleCreate: String(localized: "household.permission.roleCreate")
        case .roleUpdate: String(localized: "household.permission.roleUpdate")
        case .roleDelete: String(localized: "household.permission.roleDelete")
        }
    }
}
