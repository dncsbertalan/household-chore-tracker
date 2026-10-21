import Foundation
import SwiftData

@MainActor
protocol SyncRetryStoring {
    func checkpoint(for accountId: UUID) throws -> SyncRetryCheckpoint?
    func save(_ checkpoint: SyncRetryCheckpoint) throws
    func clear(for accountId: UUID) throws
}

@MainActor
struct SyncRetryStore: SyncRetryStoring {
    let container: ModelContainer

    func checkpoint(for accountId: UUID) throws -> SyncRetryCheckpoint? {
        let context = ModelContext(container)
        return try record(for: accountId, in: context)?.checkpoint
    }

    func save(_ checkpoint: SyncRetryCheckpoint) throws {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        do {
            if let record = try record(for: checkpoint.accountId, in: context) {
                record.update(checkpoint)
            } else {
                context.insert(SyncRetryRecord(checkpoint: checkpoint))
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func clear(for accountId: UUID) throws {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        guard let record = try record(for: accountId, in: context) else { return }
        context.delete(record)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    private func record(for accountId: UUID, in context: ModelContext) throws -> SyncRetryRecord? {
        try context.fetch(FetchDescriptor<SyncRetryRecord>(
            predicate: #Predicate { $0.accountId == accountId }
        )).first
    }
}

/// Lightweight default for isolated coordinators in previews/tests. The app explicitly injects SwiftData storage.
@MainActor
final class InMemorySyncRetryStore: SyncRetryStoring {
    private var checkpoints: [UUID: SyncRetryCheckpoint] = [:]
    func checkpoint(for accountId: UUID) -> SyncRetryCheckpoint? { checkpoints[accountId] }
    func save(_ checkpoint: SyncRetryCheckpoint) { checkpoints[checkpoint.accountId] = checkpoint }
    func clear(for accountId: UUID) { checkpoints[accountId] = nil }
}
