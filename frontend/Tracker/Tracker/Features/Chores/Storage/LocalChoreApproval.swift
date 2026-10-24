import Foundation
import SwiftData

@Model
final class LocalChoreApproval: SyncableEntity {
    @Attribute(.unique) var choreApprovalId: UUID
    var reviewedByMemberId: UUID
    var decision: ChoreApprovalDecision
    var reviewedAt: Date
    var note: String?

    var completion: LocalChoreCompletion

    var deletedAt: Date?
    var serverVersion: Int64?
    var localRevision: Int64 = 1
    var status: SyncStatus = SyncStatus.pending
    var lastSyncedAt: Date?
    var lastSyncError: String?

    init(choreApprovalId: UUID = UUID(), completion: LocalChoreCompletion,
         reviewedByMemberId: UUID, decision: ChoreApprovalDecision,
         reviewedAt: Date = .now, note: String? = nil) {
        self.choreApprovalId = choreApprovalId
        self.completion = completion
        self.reviewedByMemberId = reviewedByMemberId
        self.decision = decision
        self.reviewedAt = reviewedAt
        self.note = note
    }
}
