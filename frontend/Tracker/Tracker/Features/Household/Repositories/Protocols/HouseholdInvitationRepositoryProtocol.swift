//
//  HouseholdInvitationRepositoryProtocol.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

nonisolated protocol HouseholdInvitationRepositoryProtocol: Sendable {
    func getAllCurrentlyActive() async throws -> [HouseholdInvitationDto]
}
