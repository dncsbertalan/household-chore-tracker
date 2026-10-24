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
    case choreCreate = "CHORE_CREATE"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .view: AppLocalization.string("household.permission.view")
        case .update: AppLocalization.string("household.permission.update")
        case .delete: AppLocalization.string("household.permission.delete")
        case .memberView: AppLocalization.string("household.permission.memberView")
        case .memberInvite: AppLocalization.string("household.permission.memberInvite")
        case .memberRemove: AppLocalization.string("household.permission.memberRemove")
        case .memberAssignRole: AppLocalization.string("household.permission.memberAssignRole")
        case .roleView: AppLocalization.string("household.permission.roleView")
        case .roleCreate: AppLocalization.string("household.permission.roleCreate")
        case .roleUpdate: AppLocalization.string("household.permission.roleUpdate")
        case .roleDelete: AppLocalization.string("household.permission.roleDelete")
        case .choreCreate: AppLocalization.string("household.permission.choreCreate")
        }
    }
}
