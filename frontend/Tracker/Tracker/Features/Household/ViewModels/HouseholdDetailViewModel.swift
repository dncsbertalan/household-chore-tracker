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

    @ObservationIgnored
    private let householdRepository: any HouseholdRepositoryProtocol

    @ObservationIgnored private let householdId: UUID
    
    init(householdId: UUID, householdRepository: any HouseholdRepositoryProtocol) {
        self.householdId = householdId
        self.householdRepository = householdRepository
    }

    func load() async {
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
