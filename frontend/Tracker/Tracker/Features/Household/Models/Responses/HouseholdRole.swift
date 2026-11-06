//
//  Role.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 06..
//


import Foundation

nonisolated struct HouseholdRole: Codable, Sendable, Equatable {
        let householdRoleId: UUID
        let householdId: UUID
        let name: String
        let isSystemRole: Bool
        let permissions: [Permission]
        let version: Int64
    }
