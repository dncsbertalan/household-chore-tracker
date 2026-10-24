import Foundation

enum EntityType: String, Codable, Sendable {
    case household
}

enum MutationAction: String, Codable, Sendable {
    case create
    case update
    case delete
    case complete
}

struct OutboxOperation: Sendable {
    let id: UUID
    let accountId: UUID
    let entityType: EntityType
    let entityId: UUID
    let action: MutationAction
    let payload: Data

    init<Payload: Encodable>(
        id: UUID = UUID(),
        accountId: UUID,
        entityType: EntityType,
        entityId: UUID,
        action: MutationAction,
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

extension OutboxEntry {
    convenience init(_ operation: OutboxOperation) {
        self.init(
            id: operation.id,
            accountId: operation.accountId,
            entityType: operation.entityType.rawValue,
            entityId: operation.entityId,
            operation: operation.action.rawValue,
            payload: operation.payload
        )
    }
}
