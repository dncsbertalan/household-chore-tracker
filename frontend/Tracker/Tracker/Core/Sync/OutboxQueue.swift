import Foundation
import SwiftData

/// Uses isolated contexts so retries see fresh records and saves exclude unrelated UI edits.
@MainActor
final class OutboxQueue {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    private func makeContext() -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    private func oldest(accountId: UUID, in context: ModelContext) throws -> OutboxEntry? {
        var descriptor = FetchDescriptor<OutboxEntry>(
            predicate: #Predicate { $0.accountId == accountId },
            sortBy: [SortDescriptor(\.createdAt), SortDescriptor(\.id)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func next(accountId: UUID, now: Date = .now) throws -> QueuedOutboxOperation? {
        let context = makeContext()
        guard let entry = try oldest(accountId: accountId, in: context),
              entry.status == OutboxStatus.pending.rawValue,
              entry.nextAttemptAt <= now else { return nil }
        return QueuedOutboxOperation(
            id: entry.id, accountId: entry.accountId, entityType: entry.entityType,
            entityId: entry.entityId, action: entry.action, payload: entry.payload
        )
    }

    func nextAttemptAt(accountId: UUID) throws -> Date? {
        let context = makeContext()
        guard let entry = try oldest(accountId: accountId, in: context),
              entry.status == OutboxStatus.pending.rawValue else { return nil }
        return entry.nextAttemptAt
    }

    /// Reconcile the response and remove the command in the same local transaction.
    func acknowledge(id: UUID, applying reconciliation: any OutboxReconciliationProtocol) throws {
        let context = makeContext()
        guard let entry = try find(id: id, in: context) else { return }
        do {
            try reconciliation.apply(in: context)
            context.delete(entry)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func scheduleRetry(id: UUID, error: String, now: Date = .now) throws {
        let context = makeContext()
        guard let entry = try find(id: id, in: context) else { return }
        entry.retryCount += 1
        entry.lastError = error
        entry.nextAttemptAt = now.addingTimeInterval(min(pow(2, Double(min(entry.retryCount, 9))), 300))
        try save(context)
    }

    func block(id: UUID, reason: String) throws {
        let context = makeContext()
        guard let entry = try find(id: id, in: context) else { return }
        entry.status = OutboxStatus.blocked.rawValue
        entry.lastError = reason
        try save(context)
    }

    private func save(_ context: ModelContext) throws {
        do { try context.save() } catch {
            context.rollback()
            throw error
        }
    }

    private func find(id: UUID, in context: ModelContext) throws -> OutboxEntry? {
        try context.fetch(FetchDescriptor<OutboxEntry>(predicate: #Predicate { $0.id == id })).first
    }
}
