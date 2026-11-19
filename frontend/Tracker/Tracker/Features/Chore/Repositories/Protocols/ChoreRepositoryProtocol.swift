import Foundation

nonisolated protocol ChoreRepositoryProtocol: Sendable {
    func getAll(householdId: UUID) async throws -> [ChoreResponse]
    func get(choreId: UUID) async throws -> ChoreResponse
    func startOccurrence(choreId: UUID, version: Int64, idempotencyKey: UUID) async throws -> ChoreResponse
    func create(_ request: CreateChoreRequest, idempotencyKey: UUID) async throws
}
