import Foundation
import SwiftData

@Model
final class OutboxEntry {
    @Attribute(.unique)
    var id: UUID

    var accountId: UUID

    var entityType: String
    var entityId: UUID
    var operation: String

    var payload: Data

    var createdAt: Date
    var retryCount: Int
    var nextAttemptAt: Date

    var status: String
    var lastError: String?

    init(
        id: UUID = UUID(),
        accountId: UUID,
        entityType: String,
        entityId: UUID,
        operation: String,
        payload: Data,
        createdAt: Date = .now
    ) {
        self.id = id
        self.accountId = accountId
        self.entityType = entityType
        self.entityId = entityId
        self.operation = operation
        self.payload = payload
        self.createdAt = createdAt
        self.retryCount = 0
        self.nextAttemptAt = createdAt
        self.status = OutboxStatus.pending.rawValue
        self.lastError = nil
    }
}
