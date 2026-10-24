import Foundation
import SwiftData

struct QueuedMutation: Sendable {
    let id: UUID
    let accountId: UUID
    let entityType: String
    let entityId: UUID
    let action: String
    let payload: Data
}

@ModelActor
actor OutboxQueue {
    func next(
        accountId: UUID,
        now: Date = .now
    ) throws -> QueuedMutation? {

        let pending = OutboxStatus.pending.rawValue

        var descriptor = FetchDescriptor<OutboxEntry>(
            predicate: #Predicate {
                $0.accountId == accountId && $0.status == pending
            },
            sortBy: [
                SortDescriptor(\.createdAt),
                SortDescriptor(\.id),
            ]
        )

        // Deliberately only inspect the oldest entry.
        descriptor.fetchLimit = 1

        guard
            let entry =
                try modelContext
                .fetch(descriptor)
                .first
        else {
            return nil
        }

        // Preserve ordering if the oldest mutation is currently waiting for a retry.
        guard entry.nextAttemptAt <= now else {
            return nil
        }

        return QueuedMutation(
            id: entry.id,
            accountId: entry.accountId,
            entityType: entry.entityType,
            entityId: entry.entityId,
            action: entry.operation,
            payload: entry.payload
        )
    }

    func acknowledge(id: UUID) throws {
        if let entry = try find(id: id) {
            modelContext.delete(entry)
            try modelContext.save()
        }
    }

    func scheduleRetry(
        id: UUID,
        error: String
    ) throws {
        guard let entry = try find(id: id) else {
            return
        }

        entry.retryCount += 1
        entry.lastError = error

        // Exponential backoff, capped at 5 minutes.
        let exponent = min(entry.retryCount, 8)
        let delay = min(
            pow(2.0, Double(exponent)),
            300.0
        )

        entry.nextAttemptAt = .now
            .addingTimeInterval(delay)

        try modelContext.save()
    }

    func block(
        id: UUID,
        reason: String
    ) throws {
        guard let entry = try find(id: id) else {
            return
        }

        entry.status = OutboxStatus.blocked.rawValue
        entry.lastError = reason

        try modelContext.save()
    }

    private func find(
        id: UUID
    ) throws -> OutboxEntry? {
        let descriptor = FetchDescriptor<OutboxEntry>(
            predicate: #Predicate { $0.id == id }
        )

        return try modelContext.fetch(descriptor).first
    }
}
