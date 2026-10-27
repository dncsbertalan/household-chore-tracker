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
    // Optional while older idempotency receipts still omit audit fields.
    let createdByHouseholdMemberId: UUID?
    let updatedByHouseholdMemberId: UUID?
    let updatedAt: String?

    struct Schedule: Codable, Sendable {
        let choreScheduleId: UUID
        let scheduleType: ChoreScheduleType
        let recurrenceUnit: ChoreRecurrenceUnit?
        let recurrenceInterval: Int
        let startsAt: String?
        let timeZoneIdentifier: String
        let version: Int64
        let createdByHouseholdMemberId: UUID?
        let updatedByHouseholdMemberId: UUID?
        let createdAt: String?
        let updatedAt: String?
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
        let createdByHouseholdMemberId: UUID?
        let updatedByHouseholdMemberId: UUID?
        let updatedAt: String?
    }
}
