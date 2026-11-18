//
//  CreateHouseholdRequest.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 18..
//

import Foundation

nonisolated struct CreateHouseholdRequest: Codable, Sendable {
    let householdId: UUID
    let name: String
    let description: String?
    let roles: [CreateHouseholdRoleRequest]
    let creatorRoleId: UUID
    let householdMemberId: UUID
}
