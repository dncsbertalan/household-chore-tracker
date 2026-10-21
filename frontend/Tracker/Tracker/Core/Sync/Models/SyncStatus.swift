enum SyncStatus: String, Codable {
    case synced
    case pending
    case syncing
    case conflict
    case failed
}
