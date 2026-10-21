import Foundation
import SwiftData

@Model
final class LocalHouseholdRole : SyncableEntity {
    @Attribute(.unique) var householdRoleId: UUID
    
    var name: String
   
    var permissions: [HouseholdPermission]
    var isSystemRole: Bool
   
    var members: [LocalHouseholdMember] // relationship is mapped in LocalHouseholdMember
    var household: LocalHousehold  // relationship is mapped in LocalHousehold
    
    var deletedAt: Date?
    
    // Syncable
    var serverVersion: Int64?
    var localRevision: Int64 = 1
    var status: SyncStatus = SyncStatus.pending
    var lastSyncedAt: Date?
    var lastSyncError: String?
    
    init(householdRoleId: UUID, name: String, permissions: [HouseholdPermission], household: LocalHousehold, isSystemRole: Bool, members: [LocalHouseholdMember], deletedAt: Date? = nil, serverVersion: Int64? = nil, lastSyncedAt: Date? = nil, lastSyncError: String? = nil) {
        self.householdRoleId = householdRoleId
        self.name = name
        self.permissions = permissions
        self.household = household
        self.isSystemRole = isSystemRole
        self.members = members
        self.deletedAt = deletedAt
        self.serverVersion = serverVersion
        self.lastSyncedAt = lastSyncedAt
        self.lastSyncError = lastSyncError
    }
}
