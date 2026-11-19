//
//  PreviewHouseholdInvitationRepository.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 15..
//

import Foundation

struct PreviewHouseholdInvitationRepository: HouseholdInvitationRepositoryProtocol {
    
    func invite(householdId: UUID, request: InviteHouseholdMemberRequest, idempotencyKey: UUID) async throws {}

    func accept(invitationId: UUID, idempotencyKey: UUID) async throws {}
    
    func decline(invitationId: UUID, idempotencyKey: UUID) async throws {}

    func getAllCurrentlyActive() async throws -> [HouseholdInvitationDto] {
        HouseholdInvitationDto.mockData2
    }
}
