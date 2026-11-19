//
//  HouseholdRepository.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

import Foundation

nonisolated struct HouseholdRepository: HouseholdRepositoryProtocol {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    private struct RoleAssignmentResponse: Decodable {
        let household: HouseholdResponse
    }

    func assignRole(householdId: UUID, memberId: UUID, request: AssignHouseholdRoleRequest, idempotencyKey: UUID) async throws -> HouseholdResponse {
        let response: RoleAssignmentResponse = try await apiClient.request(
            endpoint: "api/v1/households/\(householdId)/members/\(memberId)/role",
            method: .put, body: request,
            headers: ["Idempotency-Key": idempotencyKey.uuidString.lowercased()]
        )
        return response.household
    }

    func updateNickname(householdId: UUID, memberId: UUID, request: UpdateMemberNicknameRequest, idempotencyKey: UUID) async throws -> HouseholdMemberResponse {
        try await apiClient.request(endpoint: "api/v1/households/\(householdId)/members/\(memberId)/nickname",
            method: .put, body: request, headers: ["Idempotency-Key": idempotencyKey.uuidString.lowercased()])
    }

    func create(_ request: CreateHouseholdRequest, idempotencyKey: UUID) async throws {
        try await apiClient.request(
            endpoint: "api/v1/households", method: .post, body: request,
            headers: ["Idempotency-Key": idempotencyKey.uuidString.lowercased()]
        )
    }

    func get(householdId: UUID) async throws -> HouseholdResponse {
        try await apiClient.request(endpoint: "api/v1/households/\(householdId)")
    }

    func getSummaries() async throws -> [HouseholdSummaryResponse] {
        try await apiClient.request(endpoint: "api/v1/households/summaries")
    }
}
