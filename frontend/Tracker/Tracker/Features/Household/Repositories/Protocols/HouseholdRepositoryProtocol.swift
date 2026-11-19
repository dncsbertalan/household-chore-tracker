//
//  HouseholdRepositoryProtocol.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

import Foundation

nonisolated protocol HouseholdRepositoryProtocol: Sendable {
    func assignRole(householdId: UUID, memberId: UUID, request: AssignHouseholdRoleRequest, idempotencyKey: UUID) async throws -> HouseholdResponse
    func updateNickname(householdId: UUID, memberId: UUID, request: UpdateMemberNicknameRequest, idempotencyKey: UUID) async throws -> HouseholdMemberResponse
    func create(_ request: CreateHouseholdRequest, idempotencyKey: UUID) async throws
    func get(householdId: UUID) async throws -> HouseholdResponse
    func getSummaries() async throws -> [HouseholdSummaryResponse]
}
