import Foundation

nonisolated protocol ChoreRepositoryProtocol: Sendable {
    func getAll(householdId: UUID) async throws -> [ChoreResponse]
    func create(_ request: CreateChoreRequest, idempotencyKey: UUID) async throws
}
