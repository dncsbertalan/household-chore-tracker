//
//  HouseholdRepository.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

import Foundation

nonisolated struct HouseholdInvitationRepository: HouseholdInvitationRepositoryProtocol {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func invite(householdId: UUID, request: InviteHouseholdMemberRequest, idempotencyKey: UUID) async throws {
        try await apiClient.request(
            endpoint: "api/v1/households/\(householdId)/invitations", method: .post, body: request,
            headers: ["Idempotency-Key": idempotencyKey.uuidString.lowercased()]
        )
    }

    func accept(invitationId: UUID, idempotencyKey: UUID) async throws {
        try await apiClient.request(
            endpoint: "api/v1/household-invitations/\(invitationId)/accept",
            method: .post,
            headers: ["Idempotency-Key": idempotencyKey.uuidString.lowercased()]
        )
    }
    
    func decline(invitationId: UUID, idempotencyKey: UUID) async throws {
        try await apiClient.request(
            endpoint: "api/v1/household-invitations/\(invitationId)/decline",
            method: .post,
            headers: ["Idempotency-Key": idempotencyKey.uuidString.lowercased()]
        )
    }

    func getAllCurrentlyActive() async throws -> [HouseholdInvitationDto] {
        try await apiClient.request(endpoint: "api/v1/household-invitations")
    }
}
