import Foundation

/// Internal durable payloads. Only the nested request is sent as the create endpoint's body.
nonisolated enum HouseholdInvitationCommand: Codable, Sendable, Equatable {
    case invite(householdId: UUID, request: InviteHouseholdMemberRequest)
    case respond(invitation: HouseholdInvitationResponse)
}

nonisolated struct PendingHouseholdInvitation: Identifiable, Sendable {
    let id: UUID
    let entityId: UUID
    let action: String
    let status: String
    let lastError: String?
}

nonisolated enum HouseholdInvitationError: Error, LocalizedError {
    case invalidEmail
    case invalidRole
    case notPending
    case alreadyQueued

    var errorDescription: String? {
        switch self {
        case .invalidEmail: AppLocalization.string("invitation.error.email")
        case .invalidRole: AppLocalization.string("invitation.error.role")
        case .notPending: AppLocalization.string("invitation.error.notPending")
        case .alreadyQueued: AppLocalization.string("invitation.error.alreadyQueued")
        }
    }
}
