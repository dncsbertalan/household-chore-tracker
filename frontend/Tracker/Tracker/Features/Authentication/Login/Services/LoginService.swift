import Foundation

actor LoginService: LoginServiceProtocol, LogoutServiceProtocol {
    private let client: any APIClientProtocol
    private let tokenStore: any TokenStoreProtocol
    private var isSigningIn = false
    private var sessionGeneration = 0
    private var pendingSave: Task<Void, Error>?

    init(client: any APIClientProtocol, tokenStore: any TokenStoreProtocol) {
        self.client = client
        self.tokenStore = tokenStore
    }

    func login(_ request: LoginRequest) async throws {
        guard !isSigningIn else { throw LoginError.alreadyInProgress }
        isSigningIn = true
        let generation = sessionGeneration
        defer { isSigningIn = false }
        let headers = try await CSRFService(client: client).headers()
        // Start the expiry clock before sending; network latency must not extend token validity.
        let issuedAt = Date()
        let response = try await client.request(
            endpoint: "auth/login", method: .post, body: request, headers: headers, as: TokenResponse.self
        )
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
