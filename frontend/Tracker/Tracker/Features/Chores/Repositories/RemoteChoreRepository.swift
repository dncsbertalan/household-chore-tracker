import Foundation

@MainActor
struct RemoteChoreRepository: ChoreRepositoryProtocol {
    let client: any APIClientProtocol

    func chores(accountId: UUID, householdId: UUID? = nil) async throws -> [ChoreResponse] {
        var endpoint = APIEndpoint(path: householdId.map { "households/\($0)/chores" } ?? "chores")
        endpoint.expectedAccountId = accountId
        return try await client.send(endpoint, as: [ChoreResponse].self)
    }

    func chore(id: UUID, accountId: UUID) async throws -> ChoreResponse {
        var endpoint = APIEndpoint(path: "chores/\(id)")
        endpoint.expectedAccountId = accountId
        return try await client.send(endpoint, as: ChoreResponse.self)
    }

    func update(id: UUID, accountId: UUID, request: UpdateChoreRequest, requestId: UUID) async throws -> ChoreResponse {
        var endpoint = APIEndpoint(path: "chores/\(id)", method: .put,
            headers: ["Idempotency-Key": requestId.uuidString], body: try JSONEncoder().encode(request))
        endpoint.expectedAccountId = accountId
        return try await client.send(endpoint, as: ChoreResponse.self)
    }

    func create(_ creation: ChoreCreation) async throws -> ChoreResponse {
        guard creation.hasValidDetails, creation.hasValidSchedule else { throw APIError.encodingFailed }
        var endpoint = APIEndpoint(path: "chores", method: .post,
            headers: ["Idempotency-Key": creation.requestId.uuidString],
            body: try JSONEncoder().encode(CreateChoreRequest(creation: creation)))
        endpoint.expectedAccountId = creation.createdByUserId
        return try await client.send(endpoint, as: ChoreResponse.self)
    }
}
