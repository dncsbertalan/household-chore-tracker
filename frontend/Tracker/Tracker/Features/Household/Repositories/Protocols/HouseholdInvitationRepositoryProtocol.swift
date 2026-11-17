//
//  HouseholdInvitationRepositoryProtocol.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

import Foundation

nonisolated protocol HouseholdInvitationRepositoryProtocol: Sendable {
    func accept(invitationId: UUID, idempotencyKey: UUID) async throws
    func decline(invitationId: UUID, idempotencyKey: UUID) async throws
    func getAllCurrentlyActive() async throws -> [HouseholdInvitationDto]
}
