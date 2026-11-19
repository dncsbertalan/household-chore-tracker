//
//  HouseholdDetailViewModel.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 18..
//

import Foundation
import Observation

@Observable
@MainActor
final class HouseholdDetailViewModel {
    private(set) var household: HouseholdResponse?
    private(set) var isLoading = false
    var errorMessage: String?
    private(set) var chores: [ChoreResponse] = []
    private(set) var isLoadingChores = false
    private(set) var choresErrorMessage: String?
    @ObservationIgnored private let choreRepository: any ChoreRepositoryProtocol

    @ObservationIgnored
    private let householdRepository: any HouseholdRepositoryProtocol

    @ObservationIgnored private let householdId: UUID
    
    init(householdId: UUID, householdRepository: any HouseholdRepositoryProtocol, choreRepository: any ChoreRepositoryProtocol) {
        self.choreRepository = choreRepository
        self.householdId = householdId
        self.householdRepository = householdRepository
    }

    func load() async {
        await loadHousehold()
        await loadChores()
    }

    func loadChores() async {
        guard !isLoadingChores else { return }
        isLoadingChores = true
        choresErrorMessage = nil
        defer { isLoadingChores = false }
        do {
            let response = try await choreRepository.getAll(householdId: householdId)
            try Task.checkCancellation()
            chores = response
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            choresErrorMessage = error.localizedDescription
        }
    }

    private func loadHousehold() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let response = try await householdRepository.get(householdId: householdId)
            try Task.checkCancellation()
            household = response
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }
}
