import Foundation

nonisolated struct UpdateChoreRequest: Encodable, Sendable {
    let version: Int64
    let scheduleVersion: Int64?
    let occurrenceId: UUID?
    let occurrenceVersion: Int64?
    let title: String
    let description: String?
    let pattern: String
    let recurrenceUnit: ChoreRecurrenceUnit?
    let recurrenceInterval: Int
    let startsAt: Date?
    let scheduledAt: Date?
    let dueAt: Date?
    let timeZoneIdentifier: String
    let assignedMemberIds: [UUID]
    let requiredApprovalCount: Int

    init(chore: ChoreResponse, assignedMemberIds: Set<UUID>) {
        version = chore.version
        scheduleVersion = chore.schedule?.version
        occurrenceId = chore.occurrence?.id
        occurrenceVersion = chore.occurrence?.version
        title = chore.title
        description = chore.description
        pattern = chore.schedule?.scheduleType ?? "ONCE"
        recurrenceUnit = chore.schedule?.recurrenceUnit
        recurrenceInterval = chore.schedule?.recurrenceInterval ?? 1
        startsAt = chore.schedule?.startsAt
        scheduledAt = chore.occurrence?.scheduledAt
        dueAt = chore.occurrence?.dueAt
        timeZoneIdentifier = chore.schedule?.timeZoneIdentifier ?? TimeZone.current.identifier
        self.assignedMemberIds = assignedMemberIds.sorted { $0.uuidString < $1.uuidString }
        requiredApprovalCount = chore.requiredApprovalCount
    }
}
