import Foundation
import SwiftData

/// Each submission is retained, including attempts that are subsequently rejected.
@Model
final class LocalChoreCompletion: SyncableEntity {
    @Attribute(.unique) var choreCompletionId: UUID
    var completedByMemberId: UUID
    var completedAt: Date
    var note: String?

    var occurrence: LocalChoreOccurrence
    @Relationship(deleteRule: .cascade, inverse: \LocalChoreApproval.completion)
    var approvals: [LocalChoreApproval] = []

    var deletedAt: Date?
    var serverVersion: Int64?
    var localRevision: Int64 = 1
    var status: SyncStatus = SyncStatus.pending
    var lastSyncedAt: Date?
    var lastSyncError: String?

    init(choreCompletionId: UUID = UUID(), occurrence: LocalChoreOccurrence,
         completedByMemberId: UUID, completedAt: Date = .now, note: String? = nil) {
        self.choreCompletionId = choreCompletionId
        self.occurrence = occurrence
        self.completedByMemberId = completedByMemberId
        self.completedAt = completedAt
        self.note = note
    }
}
