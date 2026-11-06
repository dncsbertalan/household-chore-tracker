//
//  HouseholdMember.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 06..
//

import Foundation

nonisolated struct HouseholdMember: Codable, Sendable {
    let householdMemberId: UUID
    let householdId: UUID

    let nickname: String?

    let userInfo: UserInfo
    let householdRole: HouseholdRole

    let joinedAt: String
    let version: Int64
}
