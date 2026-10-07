import Foundation

nonisolated protocol Registering: Sendable {
    func register(_ request: RegistrationRequest) async throws -> RegistrationResponse
}

nonisolated struct RegistrationService: Registering {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func register(_ request: RegistrationRequest) async throws -> RegistrationResponse {
        // Both calls use the same session: URLSession retains and sends the CSRF cookie.
        // Fetch a fresh token for each explicit submission; never automatically replay a POST.
        let headers = try await CSRFService(client: client).headers()
        let endpoint = try APIEndpoint.json(
            "auth/register", body: request, headers: headers
        )
        return try await client.send(endpoint, as: RegistrationResponse.self)
    }
}
