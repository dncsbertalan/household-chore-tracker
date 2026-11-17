//
//  HouseholdMemberResponse.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//


import Foundation

nonisolated struct HouseholdMemberResponse: Decodable, Identifiable, Sendable {
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
    let updatedAt: String
    let version: Int64

    var id: UUID { householdMemberId }
}
