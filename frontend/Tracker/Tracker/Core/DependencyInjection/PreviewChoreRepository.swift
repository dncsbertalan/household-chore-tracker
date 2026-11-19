import Foundation

nonisolated struct PreviewChoreRepository: ChoreRepositoryProtocol {
    func getAll(householdId: UUID) async throws -> [ChoreResponse] {
        [ChoreResponse(choreId: UUID(), householdId: householdId, title: "Wash dishes", description: "Clean up after dinner."),
         ChoreResponse(choreId: UUID(), householdId: householdId, title: "Take out the recycling", description: nil)]
    }

    func get(choreId: UUID) async throws -> ChoreResponse {
        ChoreResponse(choreId: choreId, householdId: PreviewHouseholdRepository.mockedData[0].id,
                      title: "Take out the recycling", description: nil,
                      assignedMembers: PreviewHouseholdRepository.mockedData[0].members,
                      schedule: .init(scheduleType: "ON_DEMAND", recurrenceUnit: nil, recurrenceInterval: 1),
                      actions: .init(canCreateOccurrence: true))
    }

    func startOccurrence(choreId: UUID, version: Int64, idempotencyKey: UUID) async throws -> ChoreResponse {
        var chore = try await get(choreId: choreId)
        chore.occurrence = .init(choreOccurrenceId: UUID(), scheduledAt: nil, dueAt: nil, occurrenceStatus: .pending)
        chore.occurrences = [chore.occurrence!]
        chore.actions = .init(canCreateOccurrence: false)
        return chore
    }

    func create(_ request: CreateChoreRequest, idempotencyKey: UUID) async throws {}
}
