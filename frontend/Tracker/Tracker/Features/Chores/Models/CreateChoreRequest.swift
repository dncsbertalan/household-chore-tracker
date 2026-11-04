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

    init(creation: ChoreCreation) {
        choreId = creation.choreId
        householdId = creation.householdId
        title = creation.normalizedTitle
        description = creation.normalizedDescription.isEmpty ? nil : creation.normalizedDescription
        pattern = creation.pattern
        recurrenceUnit = creation.pattern == .fixed || creation.pattern == .afterCompletion ? creation.recurrenceUnit : nil
        recurrenceInterval = creation.recurrenceInterval
        scheduledAt = ChoreTimestamp.encode(creation.scheduledAt)
        dueAt = ChoreTimestamp.encode(creation.dueAt)
        timeZoneIdentifier = creation.timeZoneIdentifier
        assignedMemberIds = creation.assignedMemberIds
        requiredApprovalCount = creation.requiredApprovalCount
        choreScheduleId = creation.pattern == .once ? nil : creation.scheduleId
        choreOccurrenceId = creation.pattern == .onDemand ? nil : creation.occurrenceId
    }
}

nonisolated enum ChoreTimestamp {
    static func encode(_ date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
    static func decode(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

}
