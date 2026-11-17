//
//  HouseholdPermission.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

import Foundation
import SwiftUI

/// Stable names from the backend's HouseholdPermission catalog; server IDs are not local IDs.
nonisolated enum HouseholdPermission: String, Codable, CaseIterable, Identifiable, Sendable {
    /// Edit the household name and description.
    case update = "HOUSEHOLD_UPDATE"

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

    case choreSelfApproveCompletion = "CHORE_SELF_APPROVE_COMPLETION"

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .update: "household.permission.update"
        case .delete: "household.permission.delete"
        case .memberView: "household.permission.memberView"
        case .memberInvite: "household.permission.memberInvite"
        case .memberRemove: "household.permission.memberRemove"
        case .memberAssignRole: "household.permission.memberAssignRole"
        case .roleView: "household.permission.roleView"
        case .roleCreate: "household.permission.roleCreate"
        case .roleUpdate: "household.permission.roleUpdate"
        case .roleDelete: "household.permission.roleDelete"
        case .choreCreate: "household.permission.choreCreate"
        case .choreUpdate: "household.permission.choreUpdate"
        case .choreDelete: "household.permission.choreDelete"
        case .choreAssignMember: "household.permission.choreAssignMember"
        case .choreComplete: "household.permission.choreComplete"
        case .choreReopen: "household.permission.choreReopen"
        case .choreSelfApproveCompletion: "household.permission.choreSelfApproveCompletion"
        case .choreApproveCompletion: "household.permission.choreApproveCompletion"
        }
    }
}
