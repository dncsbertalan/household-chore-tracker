import Foundation

nonisolated struct UpdateChoreRequest: Codable, Sendable, Equatable {
    let version: Int64
    let scheduleVersion: Int64?
    let occurrenceId: UUID?
    let occurrenceVersion: Int64?
    let title: String
    let description: String?
    let pattern: ChoreCreationPattern
    let recurrenceUnit: ChoreRecurrenceUnit?
    let recurrenceInterval: Int
    let startsAt: String?
    let scheduledAt: String?
    let dueAt: String?
    let timeZoneIdentifier: String
    let assignedMemberIds: [UUID]
    let requiredApprovalCount: Int
}
