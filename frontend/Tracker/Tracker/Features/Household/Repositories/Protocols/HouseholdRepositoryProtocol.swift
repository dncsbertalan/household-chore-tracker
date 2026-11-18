//
//  HouseholdRepositoryProtocol.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

import Foundation

nonisolated protocol HouseholdRepositoryProtocol: Sendable {
    func create(_ request: CreateHouseholdRequest, idempotencyKey: UUID) async throws
    func getSummaries() async throws -> [HouseholdSummaryResponse]
}
