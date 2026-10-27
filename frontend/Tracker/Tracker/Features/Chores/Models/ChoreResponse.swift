import Foundation

nonisolated struct ChoreResponse: Codable, Sendable {
    let choreId: UUID
    let householdId: UUID
    let title: String
    let description: String?
    let createdByUserId: UUID
    let createdAt: String
    let version: Int64
    let assignedMemberIds: [UUID]
    let requiredApprovalCount: Int
    let schedule: Schedule?
    let occurrence: Occurrence?

    struct Schedule: Codable, Sendable {
        let choreScheduleId: UUID
        let scheduleType: ChoreScheduleType
        let recurrenceUnit: ChoreRecurrenceUnit?
        let recurrenceInterval: Int
        let startsAt: String?
        let timeZoneIdentifier: String
        let version: Int64
    }

    struct Occurrence: Codable, Sendable {
        let choreOccurrenceId: UUID
        let title: String
        let description: String?
        let assignedMemberIds: [UUID]
        let requiredApprovalCount: Int
        let createdAt: String
        let scheduledAt: String?
        let dueAt: String?
        let occurrenceStatus: ChoreOccurrenceStatus
        let version: Int64
    }
}
