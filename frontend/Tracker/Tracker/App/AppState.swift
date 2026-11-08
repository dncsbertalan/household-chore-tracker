//
//  AppState.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 07..
//

import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var selectedTab: Tab = .household
    var selectedHouseholdId: UUID? = nil
    
    var sessionRevision = 0
    var isAuthenticated = false
    
    var isOnline = false
    
    func authenticationSucceeded() {
        sessionRevision += 1
        isAuthenticated = true
    }
    
    func authenticationEnded() {
        sessionRevision += 1
        isAuthenticated = false
        selectedHouseholdId = nil
        selectedTab = .household
    }

    func restoreAuthentication(from tokenStore: any TokenStoreProtocol) async {
        let revision = sessionRevision
        do {
            let tokens = try await tokenStore.load()
            // A startup read must not overwrite a login or logout that completed while it waited.
            guard revision == sessionRevision else { return }
            let now = Date()
            isAuthenticated = tokens.map {
                $0.refreshPending != true && ($0.accessExpiresAt > now || $0.refreshExpiresAt > now)
            } ?? false
        } catch {
            // An unavailable Keychain does not establish a session.
            guard revision == sessionRevision else { return }

            isAuthenticated = false
        }
    }
    
    enum Tab: Hashable {
        case household
        case chores
        case profile
    }
}
