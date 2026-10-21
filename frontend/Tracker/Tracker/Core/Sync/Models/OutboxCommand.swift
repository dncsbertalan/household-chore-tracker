import Foundation

/// A detached command envelope. Its ID is the stable key for eventual delivery retries.
/// Ownership stays outside the payload so it cannot be mistaken for server authorization.
nonisolated struct OutboxCommand: Identifiable, Sendable, Equatable {
    let id: UUID
    let accountId: UUID
    let aggregateId: UUID
    let commandType: OutboxCommandType
    let payloadVersion: Int
    let payload: Data
    let createdAt: Date

    init(id: UUID = UUID(), accountId: UUID, aggregateId: UUID, commandType: OutboxCommandType,
         payloadVersion: Int, payload: Data, createdAt: Date = Date()) {
        self.id = id
        self.accountId = accountId
        self.aggregateId = aggregateId
        self.commandType = commandType
        self.payloadVersion = payloadVersion
        self.payload = payload
        self.createdAt = createdAt
    }
}
