//
//  CreateHouseholdRoleRequest.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 18..
//

import Foundation

nonisolated struct CreateHouseholdRoleRequest: Codable, Sendable {
    let householdRoleId: UUID
    let name: String
    let permissions: Set<HouseholdPermission>
}
