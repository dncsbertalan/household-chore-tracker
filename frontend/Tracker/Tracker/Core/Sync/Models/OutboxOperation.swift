import Foundation

nonisolated struct OutboxOperation: Sendable {
    let id: UUID
    let accountId: UUID
    let entityType: OutboxEntityType
    let entityId: UUID
    let action: OutboxAction
    let payload: Data

    init<Payload: Encodable>(
        id: UUID = UUID(),
        accountId: UUID,
        entityType: OutboxEntityType,
        entityId: UUID,
        action: OutboxAction,
        payload: Payload
    ) throws {
        self.id = id
        self.accountId = accountId
        self.entityType = entityType
        self.entityId = entityId
        self.action = action

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.payload = try encoder.encode(payload)
    }
}
