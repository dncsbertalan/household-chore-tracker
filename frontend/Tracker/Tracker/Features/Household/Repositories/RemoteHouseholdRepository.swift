import Foundation

@MainActor
struct RemoteHouseholdRepository: HouseholdRepositoryProtocol {
    let client: any APIClientProtocol

    func households(accountId: UUID) async throws -> [HouseholdResponse] {
        var endpoint = APIEndpoint(path: "households")
        endpoint.expectedAccountId = accountId
        return try await client.send(endpoint, as: [HouseholdResponse].self)
    }

    func household(id: UUID, accountId: UUID) async throws -> HouseholdResponse {
        var endpoint = APIEndpoint(path: "households/\(id)")
        endpoint.expectedAccountId = accountId
        return try await client.send(endpoint, as: HouseholdResponse.self)
    }

    func create(_ creation: HouseholdCreation) async throws -> HouseholdResponse {
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
        return try await client.send(endpoint, as: HouseholdResponse.self)
    }
}
