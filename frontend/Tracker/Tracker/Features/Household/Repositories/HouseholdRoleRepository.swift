import Foundation

nonisolated struct HouseholdRoleRepository: HouseholdRoleRepositoryProtocol {
    let apiClient: APIClient
    
    func get(householdId: UUID) async throws -> HouseholdRolesResponse {
        try await apiClient.request(endpoint: "api/v1/households/\(householdId)/roles")
    }
    
    func update(householdId: UUID, roleId: UUID, request: UpdateHouseholdRoleRequest, idempotencyKey: UUID) async throws -> HouseholdRolesResponse {
        try await apiClient.request(endpoint: "api/v1/households/\(householdId)/roles/\(roleId)", method: .put,
                                    body: request, headers: ["Idempotency-Key": idempotencyKey.uuidString.lowercased()])
    }
}
