//
//  HouseholdMemberResponse.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//


import Foundation

nonisolated struct HouseholdMemberResponse: Decodable, Identifiable, Sendable, Equatable, Hashable {
    let householdMemberId: UUID
    let householdId: UUID
    let userId: UUID
    let email: String
    let firstName: String
    let lastName: String
    let nickname: String?
    let householdRole: HouseholdRoleResponse
    let joinedAt: Date
    let createdAt: Date
    let updatedAt: Date
    let version: Int64

    var id: UUID { householdMemberId }
}

nonisolated extension HouseholdMemberResponse {
    static var mockData: HouseholdMemberResponse {
        HouseholdMemberResponse(
            householdMemberId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            householdId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            userId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, email: "dancs.bertalan@icloud.com", firstName: "Bertalan", lastName: "Dancs", nickname: "Berci",
            householdRole: HouseholdRoleResponse(
                householdRoleId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                householdId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, name: "Owner", isSystemRole: false,
                permissions: HouseholdPermission.allCases, createdAt: .now, updatedAt: .now, version: 1),
            joinedAt: Date(), createdAt: Date(), updatedAt: .now, version: 1
        )
    }
    
    static var mockData2: HouseholdMemberResponse {
        HouseholdMemberResponse(
            householdMemberId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            householdId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            userId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, email: "dancs.bertalan@icloud.com", firstName: "Bertalan", lastName: "Dancs", nickname: nil,
            householdRole: HouseholdRoleResponse(
                householdRoleId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                householdId: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, name: "Owner", isSystemRole: false,
                permissions: HouseholdPermission.allCases, createdAt: .now, updatedAt: .now, version: 1),
            joinedAt: Date(), createdAt: Date(), updatedAt: .now, version: 1
        )
    }
}
