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

    private(set) var processingInvitationIDs: Set<UUID> = []
    private var completedInvitationIDs: Set<UUID> = []
    private var acceptKeys: [UUID: UUID] = [:]
    private var declineKeys: [UUID: UUID] = [:]

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
            householdInvitations = invitations.filter { !completedInvitationIDs.contains($0.id) }
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    func accept(_ invitation: HouseholdInvitationDto) async {
        await respond(to: invitation, accepting: true)
    }

    func decline(_ invitation: HouseholdInvitationDto) async {
        await respond(to: invitation, accepting: false)
    }

    private func respond(to invitation: HouseholdInvitationDto, accepting: Bool) async {
        guard invitation.status == .pending,
              !completedInvitationIDs.contains(invitation.id),
              processingInvitationIDs.insert(invitation.id).inserted else { return }
        
        defer { processingInvitationIDs.remove(invitation.id) }
        
        do {
            try await Task.sleep(for: .seconds(3))
        } catch {}
        
        errorMessage = nil

        do {
            // Keep the same key when retrying an action whose outcome is uncertain.
            if accepting {
                let key = acceptKeys[invitation.id] ?? UUID()
                acceptKeys[invitation.id] = key
                try await householdInvitationRepository.accept(invitationId: invitation.id, idempotencyKey: key)
            } else {
                let key = declineKeys[invitation.id] ?? UUID()
                declineKeys[invitation.id] = key
                try await householdInvitationRepository.decline(invitationId: invitation.id, idempotencyKey: key)
            }
            
            completedInvitationIDs.insert(invitation.id)
            householdInvitations.removeAll { $0.id == invitation.id }
            acceptKeys[invitation.id] = nil
            declineKeys[invitation.id] = nil
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

}
