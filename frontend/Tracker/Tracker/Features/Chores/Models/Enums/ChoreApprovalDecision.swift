import Foundation

nonisolated enum ChoreApprovalDecision: String, Codable, CaseIterable, Sendable {
    var title: String {
        switch self {
        case .approved: AppLocalization.string("chores.completion.approved")
        case .rejected: AppLocalization.string("chores.completion.rejected")
        }
    }
    case approved = "APPROVED"
    case rejected = "REJECTED"
}
