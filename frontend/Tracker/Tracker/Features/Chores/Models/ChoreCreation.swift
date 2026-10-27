import Foundation

nonisolated struct ChoreCreation {
    let choreId: UUID
    let householdId: UUID
    let createdByUserId: UUID
    let title: String
    let description: String
    let pattern: ChoreCreationPattern
    let recurrenceUnit: ChoreRecurrenceUnit
    let recurrenceInterval: Int
    let scheduledAt: Date?
    let dueAt: Date?
    let timeZoneIdentifier: String
    let assignedMemberIds: [UUID]
    let requiredApprovalCount: Int

    // Match the backend chore creation contract (UTF-16 code units).
    static let titleMaxLength = 100
    static let descriptionMaxLength = 500

    var normalizedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    var normalizedDescription: String { description.trimmingCharacters(in: .whitespacesAndNewlines) }

    var hasValidDetails: Bool {
        !normalizedTitle.isEmpty && normalizedTitle.utf16.count <= Self.titleMaxLength
            && normalizedDescription.utf16.count <= Self.descriptionMaxLength
    }

    var hasValidSchedule: Bool {
        guard timeZoneIdentifier.utf16.count <= 100,
              TimeZone(identifier: timeZoneIdentifier) != nil,
              recurrenceInterval > 0 else { return false }
        if pattern == .fixed && scheduledAt == nil { return false }
        if pattern == .onDemand && (scheduledAt != nil || dueAt != nil) { return false }
        if let scheduledAt, let dueAt, dueAt < scheduledAt { return false }
        return true
    }
}
