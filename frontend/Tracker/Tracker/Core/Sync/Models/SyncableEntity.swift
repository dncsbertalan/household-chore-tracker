import Foundation

protocol SyncableEntity: AnyObject {
    var deletedAt: Date? { get set }
    
    var serverVersion: Int64? { get set }
    var localRevision: Int64 { get set }
    var status: SyncStatus { get set }
    var lastSyncedAt: Date? { get set }
    var lastSyncError: String? { get set }
}

extension SyncableEntity {
    func markModified() {
        localRevision += 1
        status = .pending
        lastSyncError = nil
    }

    func markSynced(serverVersion: Int64) {
        self.serverVersion = serverVersion
        status = .synced
        lastSyncedAt = .now
        lastSyncError = nil
    }

    func markDeleted() {
        deletedAt = .now
        markModified()
    }
}
