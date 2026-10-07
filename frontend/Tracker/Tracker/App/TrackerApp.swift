//
//  TrackerApp.swift
//  Tracker
//
//  Created by Dancs Bertalan on 2026. 10. 06..
//

import SwiftUI

@main
struct TrackerApp: App {
    private let registrationService: RegistrationService?
    private let loginService: LoginService?
    private let currentUserService: CurrentUserService?

    init() {
        if let configuration = try? APIConfiguration.from() {
            let client = APIClient(configuration: configuration)
            registrationService = RegistrationService(client: client)
            let tokenStore = KeychainTokenStore(
                service: "\(Bundle.main.bundleIdentifier ?? "hu.dncs.Tracker").auth.\(configuration.baseURL.absoluteString)"
            )
            loginService = LoginService(client: client, tokenStore: tokenStore)
            let session = TokenRefreshService(client: client, tokenStore: tokenStore)
            currentUserService = CurrentUserService(
                client: AuthenticatedAPIClient(client: client, session: session)
            )
        } else {
            registrationService = nil
            loginService = nil
            currentUserService = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                registrationService: registrationService, loginService: loginService,
                currentUserService: currentUserService, logoutService: loginService
            )
        }
    }
}
