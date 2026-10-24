/// The task's lifecycle, separate from SyncableEntity.status.
nonisolated enum ChoreOccurrenceStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case inProgress
    case awaitingApproval
    case completed
    case skipped
    case cancelled
}
