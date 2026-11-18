//
//  HouseholdResponse.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 18..
//

import Foundation

nonisolated struct HouseholdResponse: Decodable, Identifiable, Sendable {
    let householdId: UUID
    let name: String
    let description: String?
    let members: [HouseholdMemberResponse]
    let roles: [HouseholdRoleResponse]
    let owner: HouseholdMemberResponse
    let me: HouseholdMemberResponse
    let createdAt: Date

    var id: UUID { householdId }
}
