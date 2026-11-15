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
final class RegisterViewModel {
    var email = ""
    var password = ""
    var firstName = ""
    var lastName = ""

    private(set) var isRegistering = false
    var showError = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    private let authService: any AuthenticationServiceProtocol

    init(authService: any AuthenticationServiceProtocol) {
        self.authService = authService
    }

    var canRegister: Bool {
        !isRegistering && !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !firstName.isEmpty && !lastName.isEmpty
    }

    func login() async {
        guard canRegister else { return }
        
        isRegistering = true
        defer { isRegistering = false }
        
        do {
            let result = try await authService.register(email: email.trimmingCharacters(in: .whitespaces),
                                                        password: password, firstName: firstName, lastName: lastName
            )
            
            print(result)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
