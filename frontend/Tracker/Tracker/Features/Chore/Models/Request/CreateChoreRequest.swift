import Foundation

nonisolated struct CreateChoreRequest: Encodable, Equatable, Sendable {
    let choreId: UUID
    let householdId: UUID
    let title: String
    let description: String?
    let pattern: ChoreCreationPattern
    let recurrenceUnit: ChoreRecurrenceUnit?
    let recurrenceInterval: Int
    let scheduledAt: Date?
    let dueAt: Date?
    let timeZoneIdentifier: String
    let assignedMemberIds: [UUID]
    let requiredApprovalCount: Int
    let choreScheduleId: UUID?
    let choreOccurrenceId: UUID?
}
