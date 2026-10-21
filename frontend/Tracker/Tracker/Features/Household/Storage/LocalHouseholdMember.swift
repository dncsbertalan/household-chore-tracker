import Foundation
import SwiftData

@Model
final class LocalHouseholdMember : SyncableEntity {
    @Attribute(.unique) var householdMemberId: UUID
    var userId: UUID
    
    var nickname: String?
    var joinedAt: Date?
    
    
    var household: LocalHousehold // relationship is mapped in LocalHousehold
    @Relationship(inverse: \LocalHouseholdRole.members)
    var role: LocalHouseholdRole
    
    var deletedAt: Date?
    
    // Syncable
    var serverVersion: Int64?
    var localRevision: Int64 = 1
    var status: SyncStatus = SyncStatus.pending
    var lastSyncedAt: Date?
    var lastSyncError: String?
    
    
    init(householdMemberId: UUID, userId: UUID, nickname: String? = nil, joinedAt: Date? = nil, household: LocalHousehold, role: LocalHouseholdRole, deletedAt: Date? = nil, serverVersion: Int64? = nil, localRevision: Int64, status: SyncStatus, lastSyncedAt: Date? = nil, lastSyncError: String? = nil) {
        self.householdMemberId = householdMemberId
        self.userId = userId
        self.nickname = nickname
        self.joinedAt = joinedAt
        self.household = household
        self.role = role
        self.deletedAt = deletedAt
        self.serverVersion = serverVersion
        self.localRevision = localRevision
        self.status = status
        self.lastSyncedAt = lastSyncedAt
        self.lastSyncError = lastSyncError
    }
}
