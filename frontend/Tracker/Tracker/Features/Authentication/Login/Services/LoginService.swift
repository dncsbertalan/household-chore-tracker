import Foundation

nonisolated protocol SigningIn: Sendable {
    func login(_ request: LoginRequest) async throws
}

actor LoginService: SigningIn, SigningOut {
    private let client: APIClient
    private let tokenStore: any TokenStoring
    private var isSigningIn = false
    private var sessionGeneration = 0
    private var pendingSave: Task<Void, Error>?

    init(client: APIClient, tokenStore: any TokenStoring) {
        self.client = client
        self.tokenStore = tokenStore
    }

    func login(_ request: LoginRequest) async throws {
        guard !isSigningIn else { throw LoginError.alreadyInProgress }
        isSigningIn = true
        let generation = sessionGeneration
        defer { isSigningIn = false }
        let headers = try await CSRFService(client: client).headers()
        let endpoint = try APIEndpoint.json("auth/login", body: request, headers: headers)
        // Start the expiry clock before sending; network latency must not extend token validity.
        let issuedAt = Date()
        let response = try await client.send(endpoint, as: TokenResponse.self)
        let tokens = try StoredTokens(response: response, issuedAt: issuedAt)
        try Task.checkCancellation()
        guard generation == sessionGeneration else { throw CancellationError() }
        let store = tokenStore
        let save = Task { try await store.save(tokens) }
        pendingSave = save
        defer { pendingSave = nil }
        try await save.value
        guard generation == sessionGeneration else { throw CancellationError() }
        // Success is reported only after secure storage succeeds. Never persist the password.
    }

    func logout() async throws {
        // Responses from logins started before logout are no longer allowed to save tokens.
        sessionGeneration += 1
        // If saving has already begun, wait for it before deleting so logout wins the race.
        if let save = pendingSave { _ = await save.result }
        try await tokenStore.clear()
        // Refresh uses conditional writes: deleting the pair also blocks late refresh results.
    }
}

nonisolated enum LoginError: Error, LocalizedError {
    case alreadyInProgress
    var errorDescription: String? { String(localized: "auth.error.alreadySigningIn") }
}

#if DEBUG
nonisolated struct LoginPreviewService: SigningIn {
    func login(_ request: LoginRequest) async throws { }
}
#endif
