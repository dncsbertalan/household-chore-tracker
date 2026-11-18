//
//  HouseholdSummaryResponse.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

import Foundation

nonisolated struct HouseholdSummaryResponse: Decodable, Identifiable, Sendable {
    let householdId: UUID
    let name: String
    let description: String?
    let members: [HouseholdMemberResponse]

    var id: UUID { householdId }
}
