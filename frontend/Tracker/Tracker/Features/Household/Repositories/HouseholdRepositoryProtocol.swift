//
//  HouseholdRepositoryProtocol.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

nonisolated protocol HouseholdRepositoryProtocol: Sendable {
    func getSummaries() async throws -> [HouseholdSummaryResponse]
}
