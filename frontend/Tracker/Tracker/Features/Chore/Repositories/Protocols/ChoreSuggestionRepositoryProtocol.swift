import Foundation

nonisolated protocol ChoreSuggestionRepositoryProtocol: Sendable {
    func suggest(householdId: UUID, description: String, timeZone: String, idempotencyKey: UUID) async throws -> ChoreSuggestion
}
