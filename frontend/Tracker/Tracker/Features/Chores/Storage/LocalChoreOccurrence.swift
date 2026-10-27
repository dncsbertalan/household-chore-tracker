import Foundation
import SwiftData

@Model
final class LocalChoreOccurrence: SyncableEntity {
    @Attribute(.unique) var choreOccurrenceId: UUID
    /// Snapshots allow this occurrence to change independently of the chore template.
    var title: String
    var choreDescription: String?
    var assignedMemberIds: [UUID]
    var requiredApprovalCount: Int
    var createdAt: Date
    var createdByHouseholdMemberId: UUID?
    var updatedByHouseholdMemberId: UUID?
    var updatedAt: Date?
    var scheduledAt: Date?
    var dueAt: Date?
    var occurrenceStatus: ChoreOccurrenceStatus

    var chore: LocalChore
    @Relationship(deleteRule: .cascade, inverse: \LocalChoreCompletion.occurrence)
    var completions: [LocalChoreCompletion] = []

    var deletedAt: Date?
    var serverVersion: Int64?
    var localRevision: Int64 = 1
    var status: SyncStatus = SyncStatus.pending
    var lastSyncedAt: Date?
    var lastSyncError: String?

    init(choreOccurrenceId: UUID = UUID(), chore: LocalChore, createdAt: Date = .now,
         scheduledAt: Date? = nil, dueAt: Date? = nil,
         occurrenceStatus: ChoreOccurrenceStatus = .pending) {
        self.choreOccurrenceId = choreOccurrenceId
        self.chore = chore
        self.title = chore.title
        self.choreDescription = chore.choreDescription
        self.assignedMemberIds = chore.assignedMemberIds
        self.requiredApprovalCount = chore.requiredApprovalCount
        self.createdAt = createdAt
        self.createdByHouseholdMemberId = chore.createdByHouseholdMemberId
        self.updatedByHouseholdMemberId = chore.createdByHouseholdMemberId
        self.updatedAt = createdAt
        self.scheduledAt = scheduledAt
        self.dueAt = dueAt
        self.occurrenceStatus = occurrenceStatus
    }
}
