import Foundation

/// Detached metadata for inspection. The payload stays in the outbox; its fingerprint detects stale actions.
nonisolated struct PendingSyncCommand: Identifiable, Equatable, Sendable {
    let id: UUID
    let aggregateId: UUID
    let commandType: OutboxCommandType?
    let payloadVersion: Int
    let createdAt: Date
    let validationFailure: SyncFailureSummary?
    private let payloadFingerprint: Data

    init(id: UUID, aggregateId: UUID, commandType: OutboxCommandType?, payloadVersion: Int,
         createdAt: Date, validationFailure: SyncFailureSummary?, payloadFingerprint: Data) {
        self.id = id
        self.aggregateId = aggregateId
        self.commandType = commandType
        self.payloadVersion = payloadVersion
        self.createdAt = createdAt
        self.validationFailure = validationFailure
        self.payloadFingerprint = payloadFingerprint
    }
}

/// Failure counters describe the whole account queue, not a proven failure of every listed command.
nonisolated struct SyncRecoveryInspection: Equatable, Sendable {
    let accountId: UUID
    let commands: [PendingSyncCommand]
    let checkpoint: SyncRetryCheckpoint?
}

nonisolated enum SyncRecoveryError: Error, Equatable, Sendable {
    case accountMismatch
    case interrupted
    case busy
    case staleInspection
    case unresolvedLocalIssue
    case nothingToRetry
}
