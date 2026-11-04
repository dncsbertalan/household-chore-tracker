import Foundation

nonisolated enum ChoreCompletionStatus: String, Codable, Sendable {
    case awaitingApproval = "AWAITING_APPROVAL"
    case approved = "APPROVED"
    case rejected = "REJECTED"

    var title: String {
        switch self {
        case .awaitingApproval: AppLocalization.string("chores.completion.awaitingApproval")
        case .approved: AppLocalization.string("chores.completion.approved")
        case .rejected: AppLocalization.string("chores.completion.rejected")
        }
    }
}
