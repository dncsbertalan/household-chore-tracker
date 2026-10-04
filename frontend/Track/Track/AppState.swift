//
//  AppState.swift
//  Track
//
//  Created by Dancs Bertalan on 2026. 10. 04..
//

import Foundation

@MainActor
@Observable
final class AppState {

    enum SessionState {
        case loading
        case guest
        case authenticated(User)
    }

    var sessionState: SessionState = .loading

    var selectedHouseholdId: UUID?
    var availableHouseholds: [HouseholdSummary] = []

    var isSyncEnabled: Bool {
        if case .authenticated = sessionState {
            return true
        }
        return false
    }
}
