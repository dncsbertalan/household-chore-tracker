import Foundation

nonisolated struct ChoreSuggestion: Decodable, Sendable {
    let title: String
    let description: String?
    let pattern: ChoreCreationPattern
    let recurrenceUnit: ChoreRecurrenceUnit?
    let recurrenceInterval: Int
    let scheduledAt: Date?
    let dueAt: Date?
    let assignedMemberIds: [UUID]
    let requiredApprovalCount: Int
    let explanation: String
}
