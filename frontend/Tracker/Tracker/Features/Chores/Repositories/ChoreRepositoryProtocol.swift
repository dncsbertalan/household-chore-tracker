import Foundation

@MainActor
protocol ChoreRepositoryProtocol {
    func chores(accountId: UUID, householdId: UUID?) async throws -> [ChoreResponse]
    func create(_ creation: ChoreCreation) async throws -> ChoreResponse
}
