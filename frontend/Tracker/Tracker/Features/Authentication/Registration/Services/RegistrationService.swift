import Foundation

nonisolated struct RegistrationService: RegistrationServiceProtocol {
    private let client: any APIClientProtocol

    init(client: any APIClientProtocol) {
        self.client = client
    }

    func register(_ request: RegistrationRequest) async throws -> RegistrationResponse {
        // Both calls use the same session: URLSession retains and sends the CSRF cookie.
        // Fetch a fresh token for each explicit submission; never automatically replay a POST.
        let headers = try await CSRFService(client: client).headers()
        return try await client.request(
            endpoint: "auth/register", method: .post, body: request, headers: headers,
            as: RegistrationResponse.self
        )
    }
}
