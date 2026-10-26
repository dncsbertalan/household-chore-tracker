import Foundation

nonisolated struct QueuedOutboxOperation: Sendable {
    let id: UUID
    let accountId: UUID
    let entityType: String
    let entityId: UUID
    let action: String
    let payload: Data
}
