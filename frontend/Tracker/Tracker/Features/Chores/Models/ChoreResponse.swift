import Foundation

nonisolated struct ChoreResponse: Codable, Sendable, Identifiable {
    var id: UUID { choreId }
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
    var occurrences: [Occurrence]? = nil
    var completions: [Completion]? = nil
    var actions: Actions? = nil
    // Optional for compatibility with earlier API responses.
    let createdByHouseholdMemberId: UUID?
    let updatedByHouseholdMemberId: UUID?
    let updatedAt: String?

    var pattern: ChoreCreationPattern {
        switch schedule?.scheduleType {
        case .fixed: .fixed
        case .afterCompletion: .afterCompletion
        case .onDemand: .onDemand
        case nil: .once
        }
    }

    var isEditable: Bool { occurrence?.isEditable ?? true }

    var pendingCompletion: Completion? {
        completions?.first { $0.choreOccurrenceId == occurrence?.id && $0.status == .awaitingApproval }
    }

    struct Actions: Codable, Sendable {
        let canComplete: Bool
        let canApprove: Bool
        let canReject: Bool
        let canCreateOccurrence: Bool
    }

    struct Completion: Codable, Sendable, Identifiable {
        var id: UUID { choreCompletionId }
        var approvedCount: Int { approvals.filter { $0.decision == .approved }.count }
        let choreCompletionId: UUID
        let choreOccurrenceId: UUID
        let completedByHouseholdMemberId: UUID
        let submittedAt: String
        let requiredApprovalCount: Int
        let status: ChoreCompletionStatus
        let resolvedAt: String?
        let version: Int64
        let approvals: [Approval]
    }

    struct Approval: Codable, Sendable, Identifiable {
        var id: UUID { choreApprovalId }
        let choreApprovalId: UUID
        let reviewedByHouseholdMemberId: UUID
        let decision: ChoreApprovalDecision
        let reviewedAt: String
    }

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

    struct Occurrence: Codable, Sendable, Identifiable {
        var id: UUID { choreOccurrenceId }
        var isEditable: Bool { occurrenceStatus == .pending || occurrenceStatus == .inProgress }
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
