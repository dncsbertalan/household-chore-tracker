import Foundation
import SwiftData

@MainActor
struct OutboxStore {
    let container: ModelContainer

    /// Reading neither claims nor sends a command. Callers receive values, never live SwiftData models.
    func pendingCommands(for accountId: UUID) throws -> [OutboxCommand] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<OutboxRecord>(
            predicate: #Predicate { $0.accountId == accountId },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor).sorted {
            $0.createdAt == $1.createdAt ? $0.commandId.uuidString < $1.commandId.uuidString : $0.createdAt < $1.createdAt
        }.map { try $0.command }
    }
}
