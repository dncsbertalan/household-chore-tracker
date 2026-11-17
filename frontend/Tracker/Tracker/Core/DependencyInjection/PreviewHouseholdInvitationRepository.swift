//
//  PreviewHouseholdInvitationRepository.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 15..
//

import Foundation

struct PreviewHouseholdInvitationRepository: HouseholdInvitationRepositoryProtocol {
    
    func getAllCurrentlyActive() async throws -> [HouseholdInvitationDto] {
        HouseholdInvitationDto.mockData2
    }
}
