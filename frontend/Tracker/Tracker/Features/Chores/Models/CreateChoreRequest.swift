import Foundation

nonisolated struct CreateChoreRequest: Codable, Sendable {
    let choreId: UUID
    let householdId: UUID
    let title: String
    let description: String?
    let pattern: ChoreCreationPattern
    let recurrenceUnit: ChoreRecurrenceUnit?
    let recurrenceInterval: Int
    let scheduledAt: String?
    let dueAt: String?
    let timeZoneIdentifier: String
    let assignedMemberIds: [UUID]
    let requiredApprovalCount: Int
    let choreScheduleId: UUID?
    let choreOccurrenceId: UUID?

    @MainActor
    init(creation: ChoreCreation, chore: LocalChore) {
        choreId = chore.choreId
        householdId = chore.household.householdId
        title = chore.title
        description = chore.choreDescription
        pattern = creation.pattern
        recurrenceUnit = chore.schedule?.recurrenceUnit
        recurrenceInterval = chore.schedule?.recurrenceInterval ?? 1
        scheduledAt = ChoreTimestamp.encode(creation.scheduledAt)
        dueAt = ChoreTimestamp.encode(creation.dueAt)
        timeZoneIdentifier = creation.timeZoneIdentifier
        assignedMemberIds = chore.assignedMemberIds
        requiredApprovalCount = chore.requiredApprovalCount
        choreScheduleId = chore.schedule?.choreScheduleId
        choreOccurrenceId = chore.occurrences.first?.choreOccurrenceId
    }
}

nonisolated enum ChoreTimestamp {
    static func encode(_ date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    static func decode(_ value: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value) else {
            throw OutboxError.invalidResponse
        }
        return date
    }
}
