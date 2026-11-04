/// The task's business lifecycle.
nonisolated enum ChoreOccurrenceStatus: String, Codable, CaseIterable, Sendable {
    case pending = "PENDING"
    case inProgress = "IN_PROGRESS"
    case awaitingApproval = "AWAITING_APPROVAL"
    case completed = "COMPLETED"
    case skipped = "SKIPPED"
    case cancelled = "CANCELLED"

}
