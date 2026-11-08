//
//  CurrentViewModel.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import Foundation
import Observation

@MainActor
@Observable
final class CurrentUserViewModel {
    private(set) var user: CurrentUser?
    private(set) var isLoading = false
    private(set) var isLoggingOut = false
    private(set) var errorMessage: String?
    
    @ObservationIgnored
    private let userRepository: any CurrentUserRepositoryProtocol
    @ObservationIgnored
    private let authService: any AuthenticationServiceProtocol
    
    @ObservationIgnored
    private let appState: AppState

    init(userRepository: any CurrentUserRepositoryProtocol, authService: any AuthenticationServiceProtocol, appState: AppState) {
        self.userRepository = userRepository
        self.authService = authService
        self.appState = appState
    }
    
    func logout() async {
        guard !isLoggingOut else { return }
        
        isLoggingOut = true
        defer { isLoggingOut = false }
                
        do {
            try await authService.logout()
            try Task.checkCancellation()
            
            // Update global application state
            appState.authenticationEnded()

        } catch is CancellationError {
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func load() async {
        guard !isLoading else { return }

        user = nil
        errorMessage = nil

        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await userRepository.getCurrentUser()
            try Task.checkCancellation()
            self.user = user
        } catch is CancellationError {
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
