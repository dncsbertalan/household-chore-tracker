import Foundation

nonisolated enum HouseholdInvitationError: Error, LocalizedError {
    case invalidEmail
    case invalidRole
    case notPending

    var errorDescription: String? {
        switch self {
        case .invalidEmail: AppLocalization.string("invitation.error.email")
        case .invalidRole: AppLocalization.string("invitation.error.role")
        case .notPending: AppLocalization.string("invitation.error.notPending")
        }
    }
}
