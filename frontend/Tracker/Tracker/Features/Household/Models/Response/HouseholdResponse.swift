//
//  HouseholdResponse.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 18..
//

import Foundation

nonisolated struct HouseholdResponse: Decodable, Identifiable, Sendable, Hashable {
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

nonisolated extension HouseholdResponse {
    static var mockData: HouseholdResponse {
        HouseholdResponse(householdId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                          name: "Home",
                          description: nil,
                          members: [
                            HouseholdMemberResponse.mockData
                          ],
                          roles: [
                            HouseholdRoleResponse(
                                householdRoleId: UUID(uuidString: "11111111-1111-1111-1111-111111111112")!,
                                householdId: UUID(uuidString: "11111111-1111-1111-1111-111111111112")!, name: "Owner", isSystemRole: false,
                                permissions: HouseholdPermission.allCases, createdAt: .now, updatedAt: .now, version: 1)
                          ],
                          owner: HouseholdMemberResponse.mockData,
                          me: HouseholdMemberResponse.mockData,
                          createdAt: .now
        )
    }
}
