//
//  HouseholdInvitationListViewModel.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 17..
//

import Foundation
import Observation

@Observable
@MainActor
final class HouseholdInvitationListViewModel {
    private(set) var householdInvitations: [HouseholdInvitationDto] = []

    private(set) var isLoading = false
    var errorMessage: String?
    
    @ObservationIgnored
    private let householdInvitationRepository: any HouseholdInvitationRepositoryProtocol
    
    init(householdInvitationRepository: any HouseholdInvitationRepositoryProtocol) {
        self.householdInvitationRepository = householdInvitationRepository
    }

    func load() async {
        guard !isLoading else { return }
        
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let invitations = try await householdInvitationRepository.getAllCurrentlyActive()
            try Task.checkCancellation()
            householdInvitations = invitations
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }
}
