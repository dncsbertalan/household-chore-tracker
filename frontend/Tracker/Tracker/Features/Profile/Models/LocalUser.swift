import Foundation
import SwiftData

@Model
final class LocalUser : SyncableEntity {
    @Attribute(.unique) var userId: UUID
    
    var firstName: String
    var lastName: String
    
    var selectedHousehold: LocalHousehold?
        
    var deletedAt: Date?

    // Syncable
    var serverVersion: Int64?
    var localRevision: Int64 = 1
    var status: SyncStatus = SyncStatus.pending
    var lastSyncedAt: Date?
    var lastSyncError: String?
    
    init(userId: UUID, firstName: String, lastName: String, selectedHousehold: LocalHousehold? = nil, deletedAt: Date? = nil, serverVersion: Int64? = nil, localRevision: Int64, status: SyncStatus, lastSyncedAt: Date? = nil, lastSyncError: String? = nil) {
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.selectedHousehold = selectedHousehold
        self.deletedAt = deletedAt
        self.serverVersion = serverVersion
        self.localRevision = localRevision
        self.status = status
        self.lastSyncedAt = lastSyncedAt
        self.lastSyncError = lastSyncError
    }
}
