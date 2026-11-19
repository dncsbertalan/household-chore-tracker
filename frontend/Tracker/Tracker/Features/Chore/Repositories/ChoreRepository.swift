import Foundation

nonisolated struct ChoreRepository: ChoreRepositoryProtocol {
    let apiClient: APIClient

    func create(_ request: CreateChoreRequest, idempotencyKey: UUID) async throws {
        try await apiClient.request(endpoint: "api/v1/chores", method: .post, body: request,
                                    headers: ["Idempotency-Key": idempotencyKey.uuidString.lowercased()])
    }
}
