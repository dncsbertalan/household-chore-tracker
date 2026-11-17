//
//  HouseholdRepository.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

nonisolated struct HouseholdInvitationRepository: HouseholdInvitationRepositoryProtocol {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func getAllCurrentlyActive() async throws -> [HouseholdInvitationDto] {
        try await apiClient.request(endpoint: "api/v1/household-invitations")
    }
}
