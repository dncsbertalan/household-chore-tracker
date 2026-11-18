//
//  HouseholdRoleResponse.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//


import Foundation

nonisolated struct HouseholdRoleResponse: Decodable, Identifiable, Sendable, Equatable, Hashable {
    let householdRoleId: UUID
    let householdId: UUID
    let name: String
    let isSystemRole: Bool
    let permissions: [PermissionResponse]
    let createdAt: Date
    let updatedAt: Date
    let version: Int64

    var id: UUID { householdRoleId }
}
