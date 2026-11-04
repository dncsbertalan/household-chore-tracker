import Foundation

@MainActor
protocol ChoreRepositoryProtocol {
    func chores(accountId: UUID, householdId: UUID?) async throws -> [ChoreResponse]
    func chore(id: UUID, accountId: UUID) async throws -> ChoreResponse
    func update(id: UUID, accountId: UUID, request: UpdateChoreRequest, requestId: UUID) async throws -> ChoreResponse
    func create(_ creation: ChoreCreation) async throws -> ChoreResponse
}
