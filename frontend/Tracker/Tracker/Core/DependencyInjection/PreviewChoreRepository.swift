import Foundation

nonisolated struct PreviewChoreRepository: ChoreRepositoryProtocol {
    func getAll(householdId: UUID) async throws -> [ChoreResponse] {
        [ChoreResponse(choreId: UUID(), householdId: householdId, title: "Wash dishes", description: "Clean up after dinner."),
         ChoreResponse(choreId: UUID(), householdId: householdId, title: "Take out the recycling", description: nil)]
    }

    func create(_ request: CreateChoreRequest, idempotencyKey: UUID) async throws {}
}
