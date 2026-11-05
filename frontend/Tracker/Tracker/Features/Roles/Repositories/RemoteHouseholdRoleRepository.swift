import Foundation

@MainActor
struct RemoteHouseholdRoleRepository: HouseholdRoleRepositoryProtocol {
    let client: any APIClientProtocol

    func roles(householdId: UUID, accountId: UUID) async throws -> HouseholdRolesResponse {
        try await send(APIEndpoint(path: "households/\(householdId)/roles"), accountId: accountId)
    }
    func createRole(householdId: UUID, accountId: UUID, request: SaveHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse {
        try await send(APIEndpoint(path: "households/\(householdId)/roles", method: .post,
            headers: ["Idempotency-Key": requestId.uuidString], body: JSONEncoder().encode(request)), accountId: accountId)
    }
    func updateRole(householdId: UUID, roleId: UUID, accountId: UUID, request: UpdateHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse {
        try await send(APIEndpoint(path: "households/\(householdId)/roles/\(roleId)", method: .put,
            headers: ["Idempotency-Key": requestId.uuidString], body: JSONEncoder().encode(request)), accountId: accountId)
    }
    func deleteRole(householdId: UUID, roleId: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws -> HouseholdRolesResponse {
        try await send(APIEndpoint(path: "households/\(householdId)/roles/\(roleId)", method: .delete,
            queryItems: [URLQueryItem(name: "version", value: String(version))], headers: ["Idempotency-Key": requestId.uuidString]), accountId: accountId)
    }
    func assignRole(householdId: UUID, memberId: UUID, accountId: UUID, request: AssignHouseholdRoleRequest, requestId: UUID) async throws -> HouseholdRolesResponse {
        try await send(APIEndpoint(path: "households/\(householdId)/members/\(memberId)/role", method: .put,
            headers: ["Idempotency-Key": requestId.uuidString], body: JSONEncoder().encode(request)), accountId: accountId)
    }
    func removeMember(householdId: UUID, memberId: UUID, version: Int64, accountId: UUID, requestId: UUID) async throws -> HouseholdMemberRemovalResponse {
        var endpoint = APIEndpoint(path: "households/\(householdId)/members/\(memberId)", method: .delete,
            queryItems: [URLQueryItem(name: "version", value: String(version))], headers: ["Idempotency-Key": requestId.uuidString])
        endpoint.expectedAccountId = accountId
        return try await client.send(endpoint, as: HouseholdMemberRemovalResponse.self)
    }
    private func send(_ endpoint: APIEndpoint, accountId: UUID) async throws -> HouseholdRolesResponse {
        var endpoint = endpoint
        endpoint.expectedAccountId = accountId
        return try await client.send(endpoint, as: HouseholdRolesResponse.self)
    }
}
