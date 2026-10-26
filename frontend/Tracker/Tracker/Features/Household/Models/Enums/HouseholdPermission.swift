import Foundation

/// Stable names from the backend's HouseholdPermission catalog; server IDs are not local IDs.
nonisolated enum HouseholdPermission: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Delete the household.
    case delete = "HOUSEHOLD_DELETE"

    /// View household members.
    case memberView = "HOUSEHOLD_MEMBER_VIEW"
    /// Invite users to the household.
    case memberInvite = "HOUSEHOLD_MEMBER_INVITE"
    /// Remove members from the household.
    case memberRemove = "HOUSEHOLD_MEMBER_REMOVE"
    /// Assign household roles to members.
    case memberAssignRole = "HOUSEHOLD_MEMBER_ASSIGN_ROLE"

    /// View household roles and their permissions.
    case roleView = "HOUSEHOLD_ROLE_VIEW"
    /// Create household roles and configure their permissions.
    case roleCreate = "HOUSEHOLD_ROLE_CREATE"
    /// Update household roles and their permissions.
    case roleUpdate = "HOUSEHOLD_ROLE_UPDATE"
    /// Delete household roles.
    case roleDelete = "HOUSEHOLD_ROLE_DELETE"

    /// Create chores in the household.
    case choreCreate = "CHORE_CREATE"
    /// Edit chore details, schedules, and recurrence.
    case choreUpdate = "CHORE_UPDATE"
    /// Delete chores in the household.
    case choreDelete = "CHORE_DELETE"
    /// Assign household members to chores.
    case choreAssignMember = "CHORE_ASSIGN_MEMBER"
    /// Mark chores assigned to the current member as completed.
    case choreComplete = "CHORE_COMPLETE"
    /// Reopen completed chores in the household.
    case choreReopen = "CHORE_REOPEN"
    /// Approve chore completions in the household.
    case choreApproveCompletion = "CHORE_APPROVE_COMPLETION"

    var id: String { rawValue }

    var title: String {
        switch self {
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
        case .choreUpdate: AppLocalization.string("household.permission.choreUpdate")
        case .choreDelete: AppLocalization.string("household.permission.choreDelete")
        case .choreAssignMember: AppLocalization.string("household.permission.choreAssignMember")
        case .choreComplete: AppLocalization.string("household.permission.choreComplete")
        case .choreReopen: AppLocalization.string("household.permission.choreReopen")
        case .choreApproveCompletion: AppLocalization.string("household.permission.choreApproveCompletion")
        }
    }
}
