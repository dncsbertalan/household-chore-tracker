import Foundation
import SwiftData

@Model
final class LocalHousehold: SyncableEntity {
    @Attribute(.unique) var householdId: UUID

    var name: String
    var householdDescription: String?

    var createdByUserId: UUID

    var deletedAt: Date?

    // Syncable
    var serverVersion: Int64?
    var localRevision: Int64 = 1
    var status: SyncStatus = SyncStatus.pending
    var lastSyncedAt: Date?
    var lastSyncError: String?

    @Relationship(deleteRule: .cascade, inverse: \LocalHouseholdRole.household)
    var householdRoles: [LocalHouseholdRole]
    @Relationship(
        deleteRule: .cascade,
        inverse: \LocalHouseholdMember.household
    )
    var householdMembers: [LocalHouseholdMember]

    @Relationship(deleteRule: .cascade, inverse: \LocalChore.household)
    var chores: [LocalChore] = []

    init(
        householdId: UUID,
        name: String,
        householdDescription: String? = nil,
        createdByUserId: UUID,
        deletedAt: Date? = nil,
        serverVersion: Int64? = nil,
        localRevision: Int64,
        status: SyncStatus,
        lastSyncedAt: Date? = nil,
        lastSyncError: String? = nil,
        householdRoles: [LocalHouseholdRole],
        householdMembers: [LocalHouseholdMember]
    ) {
        self.householdId = householdId
        self.name = name
        self.householdDescription = householdDescription
        self.createdByUserId = createdByUserId
        self.deletedAt = deletedAt
        self.serverVersion = serverVersion
        self.localRevision = localRevision
        self.status = status
        self.lastSyncedAt = lastSyncedAt
        self.lastSyncError = lastSyncError
        self.householdRoles = householdRoles
        self.householdMembers = householdMembers
    }
}
