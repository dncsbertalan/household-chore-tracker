import Foundation

/// Raw transport seam; HTTP validation and JSON handling remain in APIClient.
nonisolated protocol HTTPTransportProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
