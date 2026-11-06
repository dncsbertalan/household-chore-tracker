import Foundation

@MainActor
struct RemoteHouseholdRepository: HouseholdRepositoryProtocol, HouseholdDeletionRepositoryProtocol, HouseholdUpdateRepositoryProtocol {
    let client: any APIClientProtocol

    func households(accountId: UUID) async throws -> [Household] {
        var endpoint = APIEndpoint(path: "households")
        endpoint.expectedAccountId = accountId
        return try await client.send(endpoint, as: [Household].self)
    }

    func household(id: UUID, accountId: UUID) async throws -> Household {
        var endpoint = APIEndpoint(path: "households/\(id)")
        endpoint.expectedAccountId = accountId
        return try await client.send(endpoint, as: Household.self)
    }

    func updateHousehold(id: UUID, accountId: UUID, request: UpdateHouseholdRequest, requestId: UUID) async throws -> Household {
        var endpoint = APIEndpoint(path: "households/\(id)", method: .put,
            headers: ["Idempotency-Key": requestId.uuidString], body: try JSONEncoder().encode(request))
        endpoint.expectedAccountId = accountId
        return try await client.send(endpoint, as: Household.self)
    }

    func deleteHousehold(id: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws {
        var endpoint = APIEndpoint(path: "households/\(id)", method: .delete,
            queryItems: [URLQueryItem(name: "version", value: String(version)), URLQueryItem(name: "confirmed", value: "true")],
            headers: ["Idempotency-Key": requestId.uuidString])
        endpoint.expectedAccountId = accountId
        try await client.sendWithoutResponse(endpoint)
    }

    func create(_ creation: HouseholdCreation) async throws -> Household {
        let request = CreateHouseholdRequest(householdId: creation.householdId,
            name: HouseholdConstraints.trimmedText(creation.name),
            description: HouseholdConstraints.trimmedText(creation.description).isEmpty ? nil : HouseholdConstraints.trimmedText(creation.description),
            roles: [.init(householdRoleId: creation.creatorRoleId,
                          name: HouseholdConstraints.trimmedText(creation.roleName),
                          permissions: HouseholdPermission.allCases.filter { creation.permissions.contains($0) })],
            creatorRoleId: creation.creatorRoleId, householdMemberId: creation.householdMemberId)
        var endpoint = APIEndpoint(path: "households", method: .post,
            headers: ["Idempotency-Key": creation.requestId.uuidString], body: try JSONEncoder().encode(request))
        endpoint.expectedAccountId = creation.creatorUserId
        return try await client.send(endpoint, as: Household.self)
    }
}
