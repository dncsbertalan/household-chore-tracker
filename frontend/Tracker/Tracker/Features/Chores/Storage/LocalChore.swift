import Foundation
import SwiftData

@Model
final class LocalChore: SyncableEntity {
    @Attribute(.unique) var choreId: UUID
    var title: String
    var choreDescription: String?
    var createdByUserId: UUID
    var createdAt: Date
    var createdByHouseholdMemberId: UUID?
    var updatedByHouseholdMemberId: UUID?
    var updatedAt: Date?

    /// Household-member IDs, not user IDs. These are defaults for new occurrences.
    var assignedMemberIds: [UUID]
    /// Zero means completion does not require approval.
    var requiredApprovalCount: Int

    var household: LocalHousehold
    @Relationship(deleteRule: .cascade, inverse: \LocalChoreSchedule.chore)
    var schedule: LocalChoreSchedule?
    @Relationship(deleteRule: .cascade, inverse: \LocalChoreOccurrence.chore)
    var occurrences: [LocalChoreOccurrence] = []

    var deletedAt: Date?
    var serverVersion: Int64?
    var localRevision: Int64 = 1
    var status: SyncStatus = SyncStatus.pending
    var lastSyncedAt: Date?
    var lastSyncError: String?

    init(choreId: UUID = UUID(), title: String, choreDescription: String? = nil,
         createdByUserId: UUID, createdAt: Date = .now, household: LocalHousehold,
         assignedMemberIds: [UUID] = [], requiredApprovalCount: Int = 0,
         createdByHouseholdMemberId: UUID? = nil) {
        self.choreId = choreId
        self.title = title
        self.choreDescription = choreDescription
        self.createdByUserId = createdByUserId
        self.createdAt = createdAt
        self.createdByHouseholdMemberId = createdByHouseholdMemberId
        self.updatedByHouseholdMemberId = createdByHouseholdMemberId
        self.updatedAt = createdAt
        self.household = household
        self.assignedMemberIds = assignedMemberIds
        self.requiredApprovalCount = requiredApprovalCount
    }
}
