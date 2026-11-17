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

    private(set) var isLoading = false
    var errorMessage: String?

    @ObservationIgnored
    private let householdRepository: any HouseholdRepositoryProtocol

    init(householdRepository: any HouseholdRepositoryProtocol) {
        self.householdRepository = householdRepository
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let summaries = try await householdRepository.getSummaries()
            try Task.checkCancellation()
            householdSummaries = summaries
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }
}
