//
//  HouseholdsViewModel.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 16..
//

import Foundation
import Observation

@Observable
@MainActor
final class HouseholdsViewModel {
    private(set) var householdSummaries: [HouseholdSummaryResponse] = []
    private(set) var householdInvitations: [HouseholdInvitationDto] = []

    private(set) var isLoadingInvitations = false
    private(set) var isLoadingSummaries = false
    var summariesErrorMessage: String?
    var invitationsErrorMessage: String?

    @ObservationIgnored
    private let householdRepository: any HouseholdRepositoryProtocol
    
    @ObservationIgnored
    private let householdInvitationRepository: any HouseholdInvitationRepositoryProtocol
    
    init(householdRepository: any HouseholdRepositoryProtocol, householdInvitationRepository: any HouseholdInvitationRepositoryProtocol) {
        self.householdRepository = householdRepository
        self.householdInvitationRepository = householdInvitationRepository
    }

    func load() async {
        await loadSummaries()
        await loadInvitations()
    }
    
    func loadSummaries() async {
        guard !isLoadingSummaries else { return }
        
        summariesErrorMessage = nil
        isLoadingSummaries = true
        defer { isLoadingSummaries = false }

        do {
            let summaries = try await householdRepository.getSummaries()
            try Task.checkCancellation()
            householdSummaries = summaries
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            summariesErrorMessage = error.localizedDescription
        }
    }
    
    func loadInvitations() async {
        guard !isLoadingInvitations else { return }
        
        invitationsErrorMessage = nil
        isLoadingInvitations = true
        defer { isLoadingInvitations = false }

        do {
            let invitations = try await householdInvitationRepository.getAllCurrentlyActive()
            try Task.checkCancellation()
            householdInvitations = invitations
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            invitationsErrorMessage = error.localizedDescription
        }
    }
}
