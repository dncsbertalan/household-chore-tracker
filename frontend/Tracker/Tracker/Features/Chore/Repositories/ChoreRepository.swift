import Foundation

nonisolated struct ChoreRepository: ChoreRepositoryProtocol {
    let apiClient: APIClient

    func getAll(householdId: UUID) async throws -> [ChoreResponse] {
        try await apiClient.request(endpoint: "api/v1/households/\(householdId)/chores")
    }

    private struct StartOccurrenceRequest: Encodable { let version: Int64 }

    func get(choreId: UUID) async throws -> ChoreResponse {
        try await apiClient.request(endpoint: "api/v1/chores/\(choreId)")
    }

    func startOccurrence(choreId: UUID, version: Int64, idempotencyKey: UUID) async throws -> ChoreResponse {
        try await apiClient.request(endpoint: "api/v1/chores/\(choreId)/occurrences", method: .post,
                                    body: StartOccurrenceRequest(version: version),
                                    headers: ["Idempotency-Key": idempotencyKey.uuidString.lowercased()])
    }

    func create(_ request: CreateChoreRequest, idempotencyKey: UUID) async throws {
        try await apiClient.request(endpoint: "api/v1/chores", method: .post, body: request,
                                    headers: ["Idempotency-Key": idempotencyKey.uuidString.lowercased()])
    }
}
