//
//  LoginViewModel.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 11. 08..
//

import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var email = ""
    var password = ""

    private(set) var isLoading = false
    var showError = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let authService: any AuthenticationServiceProtocol

    @ObservationIgnored
    private let appState: AppState

    init(authService: any AuthenticationServiceProtocol, appState: AppState) {
        self.authService = authService
        self.appState = appState
    }

    var canLogin: Bool {
        !isLoading && !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    func login() async {
        guard canLogin else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await authService.login(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
            
            print(result)
            
            // Update global application state
            appState.authenticationSucceeded()
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
