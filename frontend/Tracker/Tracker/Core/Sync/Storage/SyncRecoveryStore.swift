import CryptoKit
import Foundation
import SwiftData

@MainActor
struct SyncRecoveryStore {
    let container: ModelContainer

    /// Reads account-owned records without sending, backfilling, rewriting, or acknowledging anything.
    func inspect(accountId: UUID) throws -> SyncRecoveryInspection {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let records = try context.fetch(FetchDescriptor<OutboxRecord>(
            predicate: #Predicate { $0.accountId == accountId },
            sortBy: [SortDescriptor(\.createdAt)]
        )).sorted {
            $0.createdAt == $1.createdAt ? $0.commandId.uuidString < $1.commandId.uuidString : $0.createdAt < $1.createdAt
        }
        let households = LocalHouseholdRepository(container: container)
        let summaries = records.map { record in
            let failure: SyncFailureSummary?
            do {
                failure = nil
            }
            return PendingSyncCommand(
                id: record.commandId, aggregateId: record.aggregateId,
                commandType: OutboxCommandType(rawValue: record.commandType), payloadVersion: record.payloadVersion,
                createdAt: record.createdAt, validationFailure: failure,
                payloadFingerprint: Data(SHA256.hash(data: record.payload))
            )
        }
        let checkpoint = try context.fetch(FetchDescriptor<SyncRetryRecord>(
            predicate: #Predicate { $0.accountId == accountId }
        )).first?.checkpoint
        return SyncRecoveryInspection(accountId: accountId, commands: summaries, checkpoint: checkpoint)
    }
}
