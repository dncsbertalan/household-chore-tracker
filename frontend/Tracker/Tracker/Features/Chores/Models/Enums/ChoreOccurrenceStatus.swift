/// The task's lifecycle, separate from SyncableEntity.status.
nonisolated enum ChoreOccurrenceStatus: String, Codable, CaseIterable, Sendable {
    case pending = "PENDING"
    case inProgress = "IN_PROGRESS"
    case awaitingApproval = "AWAITING_APPROVAL"
    case completed = "COMPLETED"
    case skipped = "SKIPPED"
    case cancelled = "CANCELLED"

    init(from decoder: any Decoder) throws {
        self = try ChoreEnumCoding.decode(Self.self, from: decoder)
    }
}
