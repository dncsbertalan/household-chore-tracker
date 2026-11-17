//
//  HouseholdRepository.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

nonisolated struct HouseholdRepository: HouseholdRepositoryProtocol {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func getSummaries() async throws -> [HouseholdSummaryResponse] {
        try await apiClient.request(endpoint: "api/v1/households/summaries")
    }
}
