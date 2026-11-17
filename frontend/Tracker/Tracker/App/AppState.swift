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
    
    private(set) var currentUser: CurrentUser?
    private(set) var currentUserError: String?
    var currentUserId: UUID? { currentUser?.id }

    var isOnline = false
    
    func authenticationSucceeded() {
        sessionRevision += 1
        currentUser = nil
        currentUserError = nil
        isAuthenticated = true
    }
    
    func authenticationEnded() {
        sessionRevision += 1
        isAuthenticated = false
        currentUser = nil
        currentUserError = nil
        selectedHouseholdId = nil
        selectedTab = .household
    }

    func loadCurrentUser(from repository: any CurrentUserRepositoryProtocol) async {
        guard isAuthenticated else { return }
        let revision = sessionRevision
        currentUserError = nil
        do {
            let user = try await repository.getCurrentUser()
            try Task.checkCancellation()
            guard isAuthenticated, revision == sessionRevision else { return }
            currentUser = user
        } catch {
            guard !Task.isCancelled, isAuthenticated, revision == sessionRevision else { return }
            currentUserError = error.localizedDescription
        }
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
            if !isAuthenticated {
                currentUser = nil
                currentUserError = nil
            }
        } catch {
            // An unavailable Keychain does not establish a session.
            guard revision == sessionRevision else { return }

            isAuthenticated = false
            currentUser = nil
            currentUserError = nil
        }
    }
    
    enum Tab: Hashable {
        case household
        case chores
        case profile
    }
}
