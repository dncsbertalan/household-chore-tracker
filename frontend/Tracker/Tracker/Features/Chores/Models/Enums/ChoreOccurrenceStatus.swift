import Foundation

/// The task's business lifecycle.
nonisolated enum ChoreOccurrenceStatus: String, Codable, CaseIterable, Sendable {
    var title: String {
        switch self {
        case .pending: AppLocalization.string("chores.status.pending")
        case .inProgress: AppLocalization.string("chores.status.in_progress")
        case .awaitingApproval: AppLocalization.string("chores.status.awaiting_approval")
        case .completed: AppLocalization.string("chores.status.completed")
        case .skipped: AppLocalization.string("chores.status.skipped")
        case .cancelled: AppLocalization.string("chores.status.cancelled")
        }
    }

    case pending = "PENDING"
    case inProgress = "IN_PROGRESS"
    case awaitingApproval = "AWAITING_APPROVAL"
    case completed = "COMPLETED"
    case skipped = "SKIPPED"
    case cancelled = "CANCELLED"

}
