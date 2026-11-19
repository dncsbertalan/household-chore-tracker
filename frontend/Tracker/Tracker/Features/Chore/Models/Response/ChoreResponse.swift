import Foundation

nonisolated struct ChoreResponse: Decodable, Identifiable, Sendable {
    let choreId: UUID
    let householdId: UUID
    let title: String
    let description: String?
    var assignedMembers: [HouseholdMemberResponse] = []
    var assignedMemberIds: [UUID] = []
    var requiredApprovalCount: Int = 0
    var completions: [Completion]?
    var version: Int64 = 0
    var schedule: Schedule?
    var occurrence: Occurrence?
    var occurrences: [Occurrence]?
    var actions: Actions?

    var id: UUID { choreId }
    var isOnDemand: Bool { schedule?.scheduleType == "ON_DEMAND" }

    struct Schedule: Decodable, Sendable {
        let scheduleType: String
        let recurrenceUnit: ChoreRecurrenceUnit?
        let recurrenceInterval: Int
        var version: Int64 = 0
        var startsAt: Date?
        var timeZoneIdentifier: String = "UTC"
    }
    struct Occurrence: Decodable, Identifiable, Sendable {
        let choreOccurrenceId: UUID
        let scheduledAt: Date?
        let dueAt: Date?
        let occurrenceStatus: Status
        var version: Int64 = 0
        var id: UUID { choreOccurrenceId }
    }
    enum Status: String, Decodable, Sendable {
        case pending = "PENDING", inProgress = "IN_PROGRESS", awaitingApproval = "AWAITING_APPROVAL"
        case completed = "COMPLETED", skipped = "SKIPPED", cancelled = "CANCELLED"
        var label: String {
            switch self {
            case .pending: "Pending"
            case .inProgress: "In progress"
            case .awaitingApproval: "Awaiting approval"
            case .completed: "Completed"
            case .skipped: "Skipped"
            case .cancelled: "Cancelled"
            }
        }
    }
    struct Completion: Decodable, Identifiable, Sendable {
        let choreCompletionId: UUID
        let choreOccurrenceId: UUID
        let status: String
        let version: Int64
        var id: UUID { choreCompletionId }
    }
    var pendingCompletion: Completion? {
        completions?.first { $0.choreOccurrenceId == occurrence?.id && $0.status == "AWAITING_APPROVAL" }
    }
    struct Actions: Decodable, Sendable {
        let canCreateOccurrence: Bool
        var canComplete = false
        var canApprove = false
        var canReject = false
    }
}
