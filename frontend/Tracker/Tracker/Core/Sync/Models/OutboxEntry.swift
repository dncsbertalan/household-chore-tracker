import Foundation
import SwiftData

@Model
final class OutboxEntry {
    @Attribute(.unique)
    var id: UUID

    var accountId: UUID

    var entityType: String
    var entityId: UUID
    @Attribute(originalName: "operation")
    var action: String

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
        action: String,
        payload: Data,
        createdAt: Date = .now
    ) {
        self.id = id
        self.accountId = accountId
        self.entityType = entityType
        self.entityId = entityId
        self.action = action
        self.payload = payload
        self.createdAt = createdAt
        self.retryCount = 0
        self.nextAttemptAt = createdAt
        self.status = OutboxStatus.pending.rawValue
        self.lastError = nil
    }
}

extension OutboxEntry {
    convenience init(_ operation: OutboxOperation) {
        self.init(
            id: operation.id,
            accountId: operation.accountId,
            entityType: operation.entityType.rawValue,
            entityId: operation.entityId,
            action: operation.action.rawValue,
            payload: operation.payload
        )
    }
}
